# Add to the base `Kit::Bit` class here.
class Kit::Bit < ActiveRecord::Base
  has_many :databases
end
