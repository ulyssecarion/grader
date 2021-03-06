class Submission < ActiveRecord::Base
  serialize :plagiarizing, Array

  belongs_to :author, class_name: "User"
  belongs_to :assignment
  has_many :comments, dependent: :destroy
  has_many :source_files
  has_many :activities, as: :subject, dependent: :destroy

  classy_enum_attr :status, enum: 'SubmissionStatus', allow_blank: true

  accepts_nested_attributes_for :source_files, allow_destroy: true

  validates :author_id, presence: true
  validates :assignment_id, presence: true
  validates :grade, numericality: true, allow_blank: true
  validates :max_attempts_override, numericality: { greater_than: 0 },
              allow_blank: true
  validate :validate_source_files
  validate :validate_encoding
  validates_associated :source_files

  after_create :init_status, :init_num_attempts

  def handle_create!
    create_activity_for_create
    reset_last_submitted_at
    increment_num_attempts
    execute_code!
  end

  def handle_update!
    create_activity_for_update
    reset_last_submitted_at
    init_status
    increment_num_attempts
    execute_code!
  end

  def handle_grade!
    create_activity_for_grade
    reset_last_graded_at
  end

  def handle_retest!
    init_status
    execute_code!
  end

  def max_attempts
    max_attempts_override || assignment.max_attempts
  end

  def execute_code!
    Delayed::Job.enqueue SubmissionExecutionJob.new(self.id)
  end

  def main_file
    source_files.find { |file| file.main? }
  end

  def has_outdated_grade?
    last_submitted_at && last_graded_at && last_submitted_at > last_graded_at
  end

  private

  def validate_source_files
    if self.source_files.blank?
      errors.add(:source_files, "Submission must have at least one attached file.")
    elsif self.source_files.to_a.count { |file| file.main? } != 1
      errors.add(:source_files, "Submission must have exactly one main file.")
    end
  end

  def validate_encoding
    has_invalid_encoding = source_files.any? do |file|
      path = (file.code.queued_for_write[:original] || file.code).path

      # path may be nil if the file uploaded is non-present. Other validations
      # will take care of making sure the code is present.
      path && !File.read(path).valid_encoding?
    end

    if has_invalid_encoding
      errors.add(:source_files, assignment.course.language.bad_filetype_message)
    end
  end

  def create_activity_for_create
    Activity.create(
      subject: self,
      name: 'submission_created',
      user: assignment.course.teacher
    )
  end

  def create_activity_for_update
    Activity.create(
      subject: self,
      name: 'submission_updated',
      user: assignment.course.teacher
    )
  end

  def create_activity_for_grade
    Activity.create(
      subject: self,
      name: 'submission_graded',
      user: author
    )
  end

  def reset_last_submitted_at
    update_attributes(last_submitted_at: Time.current)
  end

  def reset_last_graded_at
    update_attributes(last_graded_at: Time.current)
  end

  def init_status
    update_attributes(status: :waiting, output: nil)
  end

  def init_num_attempts
    update_attributes(num_attempts: 0)
  end

  def increment_num_attempts
    update_attributes(num_attempts: num_attempts + 1)
  end
end
