# An environment is populated with the contents of
# a site's repository at a specified commit.
# The environment's files are rooted in a temporary {#directory}.
# An environment is the primary way to interact with a site's files.
#
# An environment loads a {#config} file from the working {#directory};
# by default, `development-kit_config.yml`.
#
# Paths are all relative to the working {#directory}.
#
# ````yml
# development-kit_config.yml
#
# # asset settings
# :assets:
#   # directory to save compiled assets
#   :output: compiled
#
#   # opening and closing brackets for asset source tags
#   :src_pre: "[%"
#   :src_post: "%]"
#
#   # directories to scan for files with asset tags
#   :sources:
#     - public
#     - app/src
#
#   # all other keys are asset types
#   :javascripts:
#     # these options are passed to the Kit::Bit::Assets object
#     :options:
#       :js_compressor: :uglifier
#       :gzip: true
#     # these paths are loaded into the sprockets environment
#     :paths:
#       - assets/javascripts
#       - other/javascripts
#
#   # this is another asset type which will have it's own namespace
#   :stylesheets:
#     :options:
#       :css_compressor: :sass
#     :paths:
#       - assets/stylesheets
#   :images:
#     :options:
#       :output: images
#     :paths:
#       - assets/images
# ````
class Kit::Bit::Environment

  # Default {#options}.
  DEFAULT_OPTIONS = {
    # all environment's temporary directories will be rooted under here
    tmp_dir: '/tmp',

    # prepended to the name of the environment's working directory
    dir_prefix: 'development-kit_',

    # name of config file to load, relative to environment's working directory
    config_file: 'development-kit_config.yml'
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
    self.options = options
    self.site = site if site
    self.treeish = treeish
  end

  def options= options
    @options ||= DEFAULT_OPTIONS
    @options = @options.merge options
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
    populate unless populated
    @config = YAML.load_file "#{directory}/#{options[:config_file]}"
    validate_config if @config
  end

  # @return [Array<Kit::Bit::Assets>] assets with settings and paths loaded from config
  def assets
    @assets = []

    config[:assets].each do |type, opt|
      next if [ :sources, :output, :src_pre, :src_post ].include? type
      next if opt[:paths].nil?

      assets = Kit::Bit::Assets.new directory: directory, paths: opt[:paths]
      assets.options = { output: config[:assets][:output] } unless config[:assets][:output].nil?
      assets.options = opt[:options] unless opt[:options].nil?
      assets.type = type
      @assets << assets
    end unless config[:assets].nil?

    @assets
  end

  # @return [Array] all source files with asset tags
  def sources_with_assets
    return [] if config[:assets].nil?
    return [] if config[:assets][:sources].nil?

    @sources_with_assets = []

    opts = {}
    [ :src_pre, :src_post ].each do |opt|
      opts[opt] = config[:assets][opt] unless config[:assets][opt].nil?
    end

    config[:assets][:sources].each do |path|
      @sources_with_assets << Kit::Bit::Assets.find_tags("#{directory}/#{path}", nil, opts)
    end

    @sources_with_assets.flatten
  end

  # Finds all assets in {#sources_with_assets} and
  # generates the assets and updates the sources.
  def compile_assets
    sources_with_assets.each do |file|
      source = File.read file
      assets.each { |a| a.update_source! source }
      Kit::Bit::Utility.write source, file
    end
  end
end

private

# Checks the config file for invalid settings.
#
# - Checks that paths are not absolute or use `../` or `~/`.
def validate_config
  message = 'bad path in config'

  def safe_path?(path) Kit::Bit::Utility.safe_path?(path) end

  @config[:assets].each do |k, v|
    # skip @config[:assets][:src_pre] and @config[:assets][:src_post]
    next if [ :src_pre, :src_post ].include? k

    # process @config[:assets][:output] then go to the next option
    if k == :output
      raise RuntimeError, message unless safe_path? v
      next
    end

    # process @config[:assets][:sources] then go to the next option
    if k == :sources
      v.each_with_index do |source, i|
        raise RuntimeError, message unless safe_path? source
      end
      next
    end

    # process each asset type in @config[:assets]
    v.each do |asset_key, asset_value|
      # process :options
      if asset_key == :options
        asset_value.each do |opt_k, opt_v|
          raise RuntimeError, 'bad option in config' if opt_k == :sprockets_options
          raise RuntimeError, message if opt_k == :output && ! safe_path?(opt_v)
        end
        next
      end unless asset_value.nil?

      # process each asset path
      asset_value.each_with_index do |path, i|
        raise RuntimeError, message unless safe_path? path
      end
    end
  end unless @config[:assets].nil?
  @config
end
