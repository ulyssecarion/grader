FactoryGirl.define do
  factory :user do
    name Faker::Name.name
    sequence(:email) { |i| "user#{i}@example.com" }
    password "password"
    password_confirmation "password"
  end
end
