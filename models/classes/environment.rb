# An environment is populated with the contents of
# a site's repository at a specified commit.
# The environment's files are rooted in a temporary directory.
# An environment is the primary way to interact with a site's files.
class Kit::Bit::Environment

  # Default {#settings}.
  DEFAULT_SETTINGS = {
    # all environment's temporary directories will be rooted under here
    tmp_dir: '/tmp',

    # prepended to the name of the environment's working directory
    dir_prefix: 'development-kit_',

    # name of config file to load, relative to environment's working directory
    config_file: 'development_config.yml'
  }

  attr_reader :site, :treeish, :directory, :populated, :settings

  def initialize site: nil, treeish: nil, settings: {}
    self.settings = DEFAULT_SETTINGS.merge settings
    @populated = false
    self.site = site if site
    self.treeish = treeish if treeish
  end

  def settings= settings
    @settings = DEFAULT_SETTINGS.merge settings
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
      @directory = Kit::Bit::Utility.make_random_directory settings[:tmp_dir], "#{settings[:dir_prefix]}#{site.name}_"
    else
      @directory
    end
  end

  def cleanup
    FileUtils.remove_entry_secure directory if @directory
    @directory = nil
    @populated = false
  end

  def populate
    cleanup if populated
    raise RuntimeError, "Cannot populate without 'site'" if site.nil?
    raise RuntimeError, "Cannot populate without 'treeish'" if treeish.nil?

    Kit::Bit::Utility.extract_repo site.repo, treeish, directory
    @populated = true
  end

  def config
    raise RuntimeError, "Cannot load config unless populated" unless populated
    YAML.load_file "#{directory}/#{settings[:config_file]}"
  end
end
