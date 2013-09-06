require 'spec_helper'

describe Course do
  let(:teacher) { FactoryGirl.create(:teacher) }

  before do
    @course = teacher.taught_courses.build(name: "Example", description: "Description", language: :ruby)
  end

  subject { @course }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:teacher) }
  it { should respond_to(:students) }
  it { should respond_to(:assignments) }
  it { should respond_to(:total_points) }
  it { should respond_to(:language) }

  its(:teacher) { should eq teacher }

  it { should be_valid }

  describe "when teacher_id is not present" do
    before { @course.teacher_id = nil }

    it { should_not be_valid }
  end

  describe "when name is not present" do
    before { @course.name = "" }

    it { should_not be_valid }
  end

  describe "when description is not present" do
    before { @course.description = "" }

    it { should_not be_valid }
  end

  describe "when language is not present" do
    before { @course.language = "" }

    it { should_not be_valid }
  end

  describe "when language is not a known language" do
    before { @course.language = :french }

    it { should_not be_valid }
  end

  describe "assignment association" do
    before { @course.save! }

    let!(:assignment1) { FactoryGirl.create(:assignment, course: @course, due_time: 2.days.from_now) }
    let!(:assignment2) { FactoryGirl.create(:assignment, course: @course, due_time: 1.day.from_now) }

    it "should return soon-to-be-due assignments first" do
      expect(@course.assignments).to eq [assignment2, assignment1]
    end

    it "should destroy dependent assignments on deletion" do
      assignments = @course.assignments.to_a

      @course.destroy

      assignments.each do |assignment|
        expect { Assignment.find(assignment) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "total points" do
    before do
      @course.save!

      5.times do |n|
        FactoryGirl.create(:assignment, course: @course, point_value: n + 1)
      end
    end

    it "should correctly sum the point values of its assigmnents" do
      expect(@course.total_points).to eq (1 + 2 + 3 + 4 + 5)
    end
  end
end
