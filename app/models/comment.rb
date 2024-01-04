class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :task

  validates :content, presence: true

  def editable_by?(user)
    user == self.user
  end
end
