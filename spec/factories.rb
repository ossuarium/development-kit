FactoryGirl.define do

  factory :group, class: Kit::Group do
    id 1
    name 'default group'
    initialize_with { Kit::Group.find_or_create_by id: id }
  end

  factory :bit, class: Kit::Bit do
    id 1
    name 'a bit'
    group
  end
end
