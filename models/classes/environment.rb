# An environment is populated with the contents of
# a site's repository at a specified commit.
# The environment's files are rooted in a temporary directory.
# An environment is the primary way to interact with a site's file.
class Kit::Bit::Environment

  # All environment's temporary directories will be rooted under here.
  TMP_DIR = '/tmp'
  DIR_PREFIX = 'development-kit_'

  attr_reader :site, :treeish, :directory, :tmp_dir, :dir_prefix

  def initialize site: nil, treeish: nil, tmp_dir: TMP_DIR, dir_prefix: DIR_PREFIX
    @tmp_dir = TMP_DIR
    @dir_prefix = DIR_PREFIX
    self.site = site if site
    self.treeish = treeish if treeish
  end

  def site= site
    raise RuntimeError, "Cannot redefine 'site' once set" if self.site
    raise TypeError unless site.is_a? Kit::Bit
    @site = site
  end

  def treeish= treeish
    raise RuntimeError, "Cannot redefine 'treeish' once set" if self.treeish
    raise TypeError unless treeish.is_a? String
    @treeish = treeish
  end

  def directory
    raise RuntimeError if site.nil?
    if @directory.nil?
      @directory = Kit::Bit::Utility.make_random_directory tmp_dir, "#{dir_prefix}#{site.name}_"
    else
      @directory
    end
  end

  def cleanup
    FileUtils.remove_entry_secure directory
    @directory = nil
  end

  def populate
    raise RuntimeError, "Cannot populate without 'site'" if site.nil?
    raise RuntimeError, "Cannot populate without 'treeish'" if treeish.nil?

    Kit::Bit::Utility.extract_repo site.repo, treeish, directory
  end
end
