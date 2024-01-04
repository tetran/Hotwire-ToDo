class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :task

  validates :content, presence: true

  broadcasts_to ->(comment) { comment.task }, partial: "tasks/comments/comment"

  def editable_by?(user)
    user == self.user
  end
end
