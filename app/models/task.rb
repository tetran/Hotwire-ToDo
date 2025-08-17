class Task < ApplicationRecord
  DEFAULT_DUE_DATE = Date.new(9999, 12, 31)

  belongs_to :project
  belongs_to :created_by, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  has_many :comments, dependent: :destroy

  has_rich_text :description

  before_save :set_max_due_date
  before_save :set_inbox_id
  before_save :set_assignee_for_inbox

  validates :name, presence: true, length: { maximum: 100 }

  scope :inbox, -> { where(project: user.inbox_project) }
  scope :completed, -> { where(completed: true) }
  scope :uncompleted, -> { where(completed: false) }

  broadcasts_to :project, partial: "tasks/task"

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

  def has_due_date? = due_date&.< DEFAULT_DUE_DATE

  def display_due_date = has_due_date? ? due_date : ""

  def complete!
    update(completed: true)
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

  private

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
