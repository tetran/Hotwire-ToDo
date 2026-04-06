class TaskSeries < ApplicationRecord
  include WeekdaySupport
  include IceCubeScheduling

  belongs_to :project
  belongs_to :created_by, class_name: "User"
  belongs_to :assignee, class_name: "User", optional: true
  has_many :tasks, dependent: :nullify
  has_many :series_subtasks,
           -> { order(:position) },
           class_name: "TaskSeriesSubtask",
           dependent: :destroy,
           inverse_of: :task_series

  has_rich_text :description

  enum :frequency, { daily: 0, weekly: 1, monthly: 2, yearly: 3 }
  enum :end_mode, { infinite: 0, count: 1, until: 2 }, prefix: :end

  validates :name, presence: true, length: { maximum: 100 }
  validates :interval, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 1 }, if: :end_count?
  validates :until_date, presence: true, if: :end_until?

  before_save :derive_rrule

  def terminated?
    return true if stopped_at.present?
    return true if count_exhausted?
    return true if until_passed?

    false
  end

  def configured?
    stopped_at.blank?
  end

  def stop!
    update!(stopped_at: Time.current)
  end

  def human_label
    RruleHumanizer.new(self).to_s
  end

  def generate_next_instance!(from_task:)
    return nil if terminated?

    next_date = next_due_date_after(from_task.due_date)
    return nil if next_date.nil?
    return nil if end_until? && until_date.present? && next_date > until_date

    build_next_instance(from_task, next_date)
  end

  def sync_from_task!(task)
    assign_attributes(name: task.name, assignee_id: task.assignee_id)
    self.description = task.description.to_s
    save!
  end

  def propagate_to_pending!(except:)
    pending_siblings_except(except).find_each do |sibling|
      apply_template_to(sibling)
    end
  end

  private

    def pending_siblings_except(except)
      scope = tasks.where(completed: false)
      scope = scope.where.not(id: except.id) if except&.id.present?
      scope
    end

    def apply_template_to(sibling)
      sibling.assign_attributes(name: name, assignee_id: assignee_id)
      sibling.description = description.to_s
      sibling.save!
    end

    def count_exhausted?
      end_count? && count.present? && occurrences_generated >= count
    end

    def until_passed?
      end_until? && until_date.present? && Date.current > until_date
    end

    def build_next_instance(from_task, next_date)
      new_task = nil
      transaction do
        lock!
        return nil if terminated?
        return nil if tasks.exists?(completed: false)

        new_task = create_next_task(from_task, next_date)
        copy_description_to(new_task)
        create_subtask_copies(new_task, from_task, next_date)
        increment!(:occurrences_generated)
      end
      new_task
    end

    def create_next_task(from_task, next_date)
      tasks.create!(
        name: name,
        project_id: project_id,
        created_by_id: from_task.created_by_id,
        assignee_id: assignee_id,
        due_date: next_date,
      )
    end

    def copy_description_to(task)
      return if description.blank?

      task.description = description.to_s
      task.save!
    end

    def create_subtask_copies(parent_task, from_task, next_date)
      series_subtasks.each do |series_subtask|
        Task.create!(
          name: series_subtask.name,
          project_id: project_id,
          created_by_id: from_task.created_by_id,
          due_date: next_date,
          parent: parent_task,
        )
      end
    end

    def derive_rrule
      self.rrule = build_ice_cube_rule.to_ical
    end
end
