class Task < ApplicationRecord
  belongs_to :user

  validates :title, presence: true, length: { maximum: 100 }

  before_save :set_max_due_date

  def set_max_due_date
    self.due_date = Date.new(9999, 12, 31) if due_date.blank?
  end
end
