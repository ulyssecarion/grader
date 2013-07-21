class Course < ActiveRecord::Base
  belongs_to :teacher, class_name: "User"
  has_and_belongs_to_many :students, class_name: "User"
end