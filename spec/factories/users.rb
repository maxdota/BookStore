require 'faker'

FactoryGirl.define do 
  factory :user do |f|
    f.full_name { Faker::Name.name }
    f.username { Faker::Name.name }
    f.password { |i| i }
    f.password_confirmation { |i| i }
    f.email_address "abc@something.com"
    f.phone "01345678978"
    f.role "admin"
  end
end