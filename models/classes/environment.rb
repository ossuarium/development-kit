# An environment is populated with the contents of
# a site's repository at a specified commit.
# The environment's files are rooted in a temporary directory.
# An environment is the primary way to interact with a site's files.
class Kit::Bit::Environment

  # Default {#options}.
  DEFAULT_OPTIONS = {
    # all environment's temporary directories will be rooted under here
    tmp_dir: '/tmp',

    # prepended to the name of the environment's working directory
    dir_prefix: 'development-kit_',

    # name of config file to load, relative to environment's working directory
    config_file: 'development_config.yml'
  }
  # @!attribute options
  #   @return [Hash] options (merged with {DEFAULT_OPTIONS}}.
  #
  # @!attribute site
  #   @return [Kit::Bit] site to build the environment with
  #
  # @!attribute treeish
  #   @return [String] the reference used to pick the commit to build the environment with
  #
  # @!attribute [r] directory
  #   @return [String] the environment's working directory
  #
  # @!attribute [r] populated
  #   @return [Boolean] true if the site's repo has been extracted
  attr_reader :options, :site, :treeish, :directory, :populated

  def initialize site: nil, treeish: 'master', options: {}
    @populated = false
    self.options = DEFAULT_OPTIONS.merge options
    self.site = site if site
    self.treeish = treeish
  end

  def options= options
    @options = DEFAULT_OPTIONS.merge options
  end

  def site= site
    raise RuntimeError, "Cannot redefine 'site' once populated" if populated
    raise TypeError unless site.is_a? Kit::Bit
    @site = site
  end

  def treeish= treeish
    raise RuntimeError, "Cannot redefine 'treeish' once populated" if populated
    raise TypeError unless treeish.is_a? String
    @treeish = treeish
  end

  def directory
    raise RuntimeError if site.nil?
    if @directory.nil?
      @directory = Kit::Bit::Utility.make_random_directory options[:tmp_dir], "#{options[:dir_prefix]}#{site.name}_"
    else
      @directory
    end
  end

  # Removes the environment's working directory.
  def cleanup
    FileUtils.remove_entry_secure directory if @directory
    @directory = nil
    @populated = false
  end

  # Extracts the site's files from repository to the working directory.
  def populate
    cleanup if populated
    raise RuntimeError, "Cannot populate without 'site'" if site.nil?
    raise RuntimeError, "Cannot populate without 'treeish'" if treeish.empty?

    Kit::Bit::Utility.extract_repo site.repo, treeish, directory
    @populated = true
  end

  # @return [Hash] configuration loaded from {#options}`[:config_file]` under {#directory}
  def config
    raise RuntimeError, "Cannot load config unless populated" unless populated
    YAML.load_file "#{directory}/#{options[:config_file]}"
  end
end
