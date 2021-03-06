class Comment < ActiveRecord::Base
  # TODO add tests for this
  scope :created, -> { where.not(id: nil) }

  belongs_to :user
  belongs_to :submission
  has_many :activities, as: :subject, dependent: :destroy

  default_scope -> { order('created_at ASC') }

  validates :user_id, presence: true
  validates :submission_id, presence: true
  validates :content, presence: true

  def handle_create!
    create_activity
    notify_submission
  end

  def create_activity
    target_user = if user == submission.author
      submission.assignment.course.teacher
    else
      submission.author
    end

    Activity.create(
      subject: self,
      name: 'comment_created',
      user: target_user
    )
  end

  # If this comment is one written by the teacher, then this comment is an
  # indication that the teacher has reviewed the submission.
  def notify_submission
    unless user == submission.author
      submission.last_graded_at = self.updated_at
      submission.save
    end
  end
end
