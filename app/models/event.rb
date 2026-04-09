class Event < ApplicationRecord
  EVENT_NAMES = %w[
    task_created
    task_completed
    task_updated
    task_deleted
    comment_posted
    project_created
    assignee_changed
    due_date_set
  ].freeze

  FEATURE_CATEGORIES = {
    "task_created" => "basic_operation",
    "task_completed" => "basic_operation",
    "task_updated" => "basic_operation",
    "task_deleted" => "basic_operation",
    "comment_posted" => "collaboration",
    "project_created" => "basic_operation",
    "assignee_changed" => "collaboration",
    "due_date_set" => "planning",
  }.freeze

  belongs_to :user
  belongs_to :project, optional: true
  belongs_to :task, optional: true

  validates :event_name, presence: true, inclusion: { in: EVENT_NAMES }
  validates :occurred_at, presence: true
  validates :feature_category, presence: true

  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :by_project, ->(project_id) { where(project_id: project_id) }
  scope :by_event_name, ->(name) { where(event_name: name) }
  scope :occurred_from, ->(time) { where(occurred_at: time..) }
  scope :occurred_to, ->(time) { where(occurred_at: ..time.end_of_day) }
  scope :recent, -> { order(occurred_at: :desc) }

  scope :filter_by, lambda { |params|
    scope = all
    scope = scope.by_user(params[:user_id]) if params[:user_id].present?
    scope = scope.by_project(params[:project_id]) if params[:project_id].present?
    scope = scope.by_event_name(params[:event_name]) if params[:event_name].present?
    scope = scope.occurred_from(Time.zone.parse(params[:from])) if params[:from].present?
    scope = scope.occurred_to(Time.zone.parse(params[:to])) if params[:to].present?
    scope
  }
end
