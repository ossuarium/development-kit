require 'sprockets'

# Flexible asset pipeline using Sprockets.
# Paths are loaded into a Sprockets::Environment (relative to directory if given).
# Asset tags are used in source code and replaced with generated asset path.
class Kit::Bit::Assets

  # Default settings.
  DEFAULT_SETTINGS = {
    # default path to output all saved assets;
    #  can be relative to directory or absolute
    output: '',

    # keyword to use in asset tag for inline assets
    inline: 'inline',

    # if true, also generate a gzipped asset
    gzip: false,

    # opening and closing brackets for asset source tags
    src_pre: '[%',
    src_post: '%]',

    # allowed settings for Sprockets::Environment
    sprockets_cfg: [ :js_compressor, :css_compressor ]
  }

  # @!attribute directory
  #   @return [String] directory which all paths will be relative to if set
  #
  # @!attribute settings
  #   @return [Hash] settings (merged with defaults).
  #
  # @!attribute paths
  #   @return [Array] paths to load into sprockets environment
  #
  # @!attribute targets
  #   @return [Array<String,String>] logical path,
  attr_accessor :directory, :settings, :paths, :type
  attr_reader :settings, :targets

  def initialize directory: '', settings: {}, paths: {}
    self.directory = directory
    self.settings = DEFAULT_SETTINGS.merge settings
    self.paths = paths
  end

  def settings= settings
    @settings = DEFAULT_SETTINGS.merge settings
  end

  # @return [Sprockets::Environment] the current Sprockets::Environment
  def sprockets
    @sprockets ||= Sprockets::Environment.new
  end

  # Load settings into the sprockets environment.
  # Values are loaded from #settings.
  def load_settings
    settings[:sprockets_cfg].each do |cfg|
      sprockets.send "#{cfg}=".to_sym, settings[cfg] if settings[cfg]
    end
  end

  # Load paths into the sprockets environment.
  # Values are loaded from #paths.
  def load_paths
    paths.each do |path|
      sprockets.append_path "#{directory + '/' unless directory.empty?}#{path}"
    end
  end

  # @return [Sprockets::Environment] sprockets environment with settings and paths loaded
  def assets
    unless @loaded
      load_settings
      load_paths
    end
    @loaded = true
    sprockets
  end

  # Write a target asset to file with a hashed name.
  # @param target [String] logical path to asset
  # @param path [String] where the asset will be written relative to
  # @param gzip [Boolean] if the asset should be gzipped
  # @return [String, nil] the relative path to the written asset or nil if no such asset
  def write target, path: settings[:output], gzip: settings[:gzip]
    asset = assets[target]

    return if asset.nil?

    hashed_name = Kit::Bit::Utility.hash_name asset.logical_path.to_s, asset.to_s

    if path.empty?
      path = directory
    elsif ! directory.empty?
      path = "#{directory}/#{path}"
    end unless path =~ /^\//

    path += '/' unless path.empty?
    path += hashed_name

    asset.write_to "#{path}.gz", compress: true if gzip
    asset.write_to path
    hashed_name
  end

  # Replaces all asset tags in source string with asset path or asset source.
  # Writes any assets
  def update_source! source
      # /\[%\s+javascript\s+((\S+)\s?(\S+))\s+%\]/
      regex = /#{Regexp.escape settings[:src_pre]}\s+#{type.to_s.singularize}\s+((\S+)\s?(\S+))\s+#{Regexp.escape settings[:src_post]}/
        source.gsub! regex do
        if $2 == settings[:inline]
          assets[$3].to_s
        else
          write $1
        end
      end
  end

  def update_source source
    s = source
    update_source! s
    s
  end
end
