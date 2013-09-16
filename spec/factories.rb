FactoryGirl.define do

  factory :group, class: Kit::Group do
    sequence(:id) { |n| n }
    name 'my_group'
    initialize_with { Kit::Group.find_or_create_by name: name }
  end

  factory :bit, class: Kit::Bit do
    sequence(:id) { |n| n }
    name 'my_site'
    group
    root_domain 'example.com'
    initialize_with { Kit::Bit.find_or_create_by name: name }
  end

  factory :database, class: Kit::Database do
    sequence(:id) { |n| n }
    name 'my_db'
    bit
  end
end
