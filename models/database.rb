# New database objects are created with an associated bit giving
# each a set of associated databases.
# Instance methods then interact directly with that database.
class Kit::Database < ActiveRecord::Base
  belongs_to :bit
end
