# Add to the base `Kit::Bit` class here.
require 'require_all'
require 'grit'

require_rel 'classes'

# Bits in this kit are sites.
# Sites in a single group all use the same repository.
# Individual sites represent different deployments.
class Kit::Bit < ActiveRecord::Base

  has_many :databases

  PRODUCTION ||= 'production'

  # The git repository for this bit as a Grit::Repo.
  # @return [Grit::Repo]
  def repo
    Grit::Git.git_max_size = 100 * 1048576
    @repo ||= Grit::Repo.new group.repository
  end

  # Returns fully qualified domain name.
  # Non-production sites are at a subdomain given by their name.
  # @return [String] fully qualified domain name
  def domain
    if name == PRODUCTION
      self.root_domain
    else
      "#{name}.#{root_domain}"
    end
  end
end
