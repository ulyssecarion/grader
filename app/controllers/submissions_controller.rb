class SubmissionsController < ApplicationController
  def show
    @submission = Submission.find(params[:id])
    authorize @submission

    @comment = @submission.comments.build
  end

  def new
    @assignment = Assignment.find(params[:assignment_id])
    @submission = @assignment.submissions.build

    authorize @submission

    @submission.source_files.build
  end

  def create
    @assignment = Assignment.find(params[:assignment_id])
    @submission = Submission.new(submission_params)

    authorize @submission

    if @submission.save
      @submission.handle_create!

      flash[:success] = "Your submission was created successfully."
      redirect_to @submission
    else
      render 'new'
    end
  end

  def edit
    @submission = Submission.find(params[:id])
    authorize @submission
  end

  def update
    @submission = Submission.find(params[:id])
    authorize @submission

    if @submission.update_attributes(submission_update_params)
      @submission.handle_update!

      flash[:success] = "Your submission was successfully updated."
      redirect_to @submission
    else
      render 'edit'
    end
  end

  def index
    @assignment = Assignment.find(params[:assignment_id])
    authorize @assignment, :list_submissions?

    @submissions = sort_submissions(policy_scope(@assignment.submissions))
  end

  def grade
    @submission = Submission.find(params[:id])
    authorize @submission

    if @submission.update_attributes(submission_grading_params)
      @submission.handle_grade!

      flash[:success] = "The submission was updated successfully."
      redirect_to @submission
    else
      redirect_to @submission, flash: { error: submission_error_message }
    end
  end

  def override_max_attempts
    @submission = Submission.find(params[:id])
    authorize @submission

    if @submission.update_attributes(submission_override_attempts_params)
      flash[:success] = "The submission was updated successfully."
      redirect_to @submission
    else
      redirect_to @submission, flash: { error: submission_error_message }
    end
  end

  def force_retest
    @submission = Submission.find(params[:id])
    authorize @submission

    @submission.handle_retest!
    redirect_to @submission
  end

  def destroy
    @submission = Submission.find(params[:id])
    authorize @submission

    submission = @submission.delete
    flash[:success] = "Submission was destroyed successfully."
    redirect_to submission.assignment
  end

  private

  def submission_params
    params.require(:submission).permit(:assignment_id, :author_id,
      source_files_attributes: source_file_params)
  end

  def submission_grading_params
    params.require(:submission).permit(:grade)
  end

  def submission_update_params
    params.require(:submission).permit(source_files_attributes: source_file_params)
  end

  def submission_override_attempts_params
    params.require(:submission).permit(:max_attempts_override)
  end

  def source_file_params
    [ :code, :main, :id, :_destroy ]
  end

  def sort_submissions(submissions)
    case params[:sort]
    when 'author'
      sorted = submissions.sort_by { |s| s.author.name }

      if sort_order == :asc
        sorted
      else
        sorted.reverse
      end
    when 'status'
      submissions.order(status: sort_order)
    when 'grade'
      submissions.order(grade: sort_order)
    else
      submissions
    end
  end

  def sort_order
    if params[:order] == 'asc'
      :asc
    else
      :desc
    end
  end

  # only show the first one, because otherwise it looks weird in an alert
  def submission_error_message
    "Error with your update: #{@submission.errors.full_messages.first}"
  end
end
