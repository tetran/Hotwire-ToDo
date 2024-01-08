class Project < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :tasks, dependent: :destroy
  has_many :project_members, dependent: :destroy
  has_many :members, through: :project_members, source: :user

  after_create :add_owner_to_members

  validates :name, presence: true, length: { maximum: 100 }

  scope :unarchived, -> { where(archived: false) }
  scope :archived, -> { where(archived: true) }

  def archive!
    update!(archived: true)
  end

  def unarchive!
    update!(archived: false)
  end

  def inbox? = dedicated

  def display_name
    dedicated ? I18n.t("project.inbox") : name
  end

  private

    def add_owner_to_members
      members << owner
    end
end
