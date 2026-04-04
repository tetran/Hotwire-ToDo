class Task < ApplicationRecord
  DEFAULT_DUE_DATE = Date.new(9999, 12, 31)

  belongs_to :project
  belongs_to :created_by, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  belongs_to :parent, class_name: "Task", optional: true, inverse_of: :subtasks
  has_many :subtasks, class_name: "Task", foreign_key: :parent_id, dependent: :destroy, inverse_of: :parent
  has_many :comments, dependent: :destroy

  has_rich_text :description

  before_save :set_max_due_date
  before_save :set_inbox_id
  before_save :set_assignee_for_inbox

  validates :name, presence: true, length: { maximum: 100 }
  validate :parent_must_be_root_task
  validate :subtask_same_project_as_parent

  scope :inbox, -> { where(project: user.inbox_project) }
  scope :completed, -> { where(completed: true) }
  scope :uncompleted, -> { where(completed: false) }
  scope :root_tasks, -> { where(parent_id: nil) }

  after_create_commit :broadcast_task_create, unless: :subtask?
  after_update_commit :broadcast_task_update, unless: :subtask?
  after_destroy_commit :broadcast_task_destroy, unless: :subtask?

  after_create_commit :broadcast_parent_on_subtask_create, if: :subtask?
  after_destroy_commit :broadcast_parent_update_on_destroy, if: :subtask?
  after_update_commit :broadcast_parent_on_subtask_update, if: -> { subtask? && saved_change_to_completed? }

  def self.create_from_suggestion(params, project_id, user)
    tasks = []
    transaction do
      params.each_value do |param|
        # insert_allを使いたいが、descriptionはActionTextなので何らかの調整が必要
        tasks << Task.create!(
          name: param[:name],
          description: param[:description],
          due_date: param[:due_date],
          project_id: project_id,
          created_by: user,
        )
      end
    end
    tasks
  end

  def self.create_subtasks_from_suggestion(params, parent_task)
    tasks = []
    transaction do
      params.each_value do |param|
        tasks << Task.create!(
          name: param[:name],
          description: param[:description],
          due_date: param[:due_date],
          project_id: parent_task.project_id,
          created_by: parent_task.created_by,
          parent: parent_task,
        )
      end
    end
    tasks
  end

  def has_due_date? = due_date&.< DEFAULT_DUE_DATE

  def display_due_date = has_due_date? ? due_date : ""

  def complete!
    transaction do
      update(completed: true)
      subtasks.uncompleted.update_all(completed: true, updated_at: Time.current) if subtasks.any?
    end
  end

  def uncomplete!
    update(completed: false)
  end

  def assign!(assignee_id)
    update!(assignee: project.members.find(assignee_id))
  end

  def unassign!
    update!(assignee: nil)
  end

  def overdue? = due_date < Date.current

  def subtask? = parent_id.present?

  def parent?
    subtasks.loaded? ? subtasks.any? : subtasks.exists?
  end

  private

    def parent_must_be_root_task
      return unless parent_id.present? && parent&.parent_id.present?

      errors.add(:parent_id, :nested_too_deep)
    end

    def subtask_same_project_as_parent
      return unless parent_id.present? && parent.present? && project_id != parent.project_id

      errors.add(:project_id, :must_match_parent)
    end

    def broadcast_task_create
      broadcast_append_to project, target: "tasks", partial: "tasks/task", locals: { task: self }
    end

    def broadcast_task_update
      subtasks.load if parent? && !subtasks.loaded?
      broadcast_replace_to project, partial: "tasks/task", locals: { task: self }
    end

    def broadcast_task_destroy
      broadcast_remove_to project
    end

    def broadcast_parent_on_subtask_create
      reloaded = parent.reload.tap { |t| t.subtasks.load }
      reloaded.broadcast_replace_to(reloaded.project, partial: "tasks/task", locals: { task: reloaded })
    end

    def broadcast_parent_on_subtask_update
      parent.broadcast_replace_to(parent.project, partial: "tasks/task", locals: { task: parent })
    end

    def broadcast_parent_update_on_destroy
      return unless Task.exists?(parent_id)

      reloaded_parent = Task.find(parent_id)
      reloaded_parent.broadcast_replace_to(
        reloaded_parent.project,
        partial: "tasks/task",
        locals: { task: reloaded_parent },
      )
    end

    def set_max_due_date
      self.due_date = DEFAULT_DUE_DATE if due_date.blank?
    end

    def set_inbox_id
      self.project_id = user.inbox_project.id if project_id.blank?
    end

    def set_assignee_for_inbox
      self.assignee_id = created_by_id if project.dedicated
    end
end
