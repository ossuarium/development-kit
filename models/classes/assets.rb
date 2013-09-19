require 'sprockets'

# Flexible asset pipeline using Sprockets.
# Paths are loaded into a `Sprockets::Environment` (relative to {#directory} if given).
# Asset tags are used in source code and replaced
#with generated asset path or compiled source if `inline` is used.
#
# For example, if type is set to `:javascripts` the following replacements would be made:
#
#     [% javascript app %] -> app-9413c7f112033f0c6f2a8e8dd313399c18d93878.js
#     [% javascript lib/jquery %] -> lib/jquery-e2a8cde3f5b3cdb011e38a673556c7a94729e0d1.js
#     [% javascript inline tracking %] -> <compiled source of tracking.js asset>
#
class Kit::Bit::Assets

  # Default {#settings}.
  DEFAULT_SETTINGS = {
    # default path to output all saved assets;
    # can be relative to directory or absolute
    output: '',

    # keyword to use in asset tag for inline assets
    inline: 'inline',

    # if true, also generate a gzipped asset
    gzip: false,

    # opening and closing brackets for asset source tags
    src_pre: '[%',
    src_post: '%]',

    # allowed options for `Sprockets::Environment`
    sprockets_options: [ :js_compressor, :css_compressor ]
  }

  # @!attribute directory
  #   @return [String] directory which all paths will be relative to if set
  #
  # @!attribute settings
  #   @return [Hash] settings (merged with {DEFAULT_SETTINGS}}.
  #
  # @!attribute paths
  #   @return [Array] paths to load into sprockets environment
  #
  # @!attribute type
  #   @return [Symbol] type of asset
  attr_accessor :directory, :paths, :type
  attr_reader :settings

  def initialize directory: '', settings: {}, paths: {}
    self.settings = DEFAULT_SETTINGS.merge settings
    self.directory = directory
    self.paths = paths
  end

  def settings= settings
    @settings = DEFAULT_SETTINGS.merge settings
  end

  # @return [Sprockets::Environment] the current sprockets environment
  def sprockets
    @sprockets ||= Sprockets::Environment.new
  end

  # Load settings into the sprockets environment.
  # Values are loaded from {#settings}.
  def load_settings
    settings[:sprockets_options].each do |cfg|
      sprockets.send "#{cfg}=".to_sym, settings[cfg] if settings[cfg]
    end
  end

  # Load paths into the sprockets environment.
  # Values are loaded from {#paths}.
  def load_paths
    paths.each do |path|
      sprockets.append_path "#{directory + '/' unless directory.empty?}#{path}"
    end
  end

  # @return [Sprockets::Environment] sprockets environment with {#settings} and {#paths} loaded
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
  # @return [String, nil] the relative path to the written asset or `nil` if no such asset
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

  # (see #update_source)
  # @note this modifies the `source` `String` in place
  def update_source! source
      # e.g. /\[%\s+javascript\s+((\S+)\s?(\S+))\s+%\]/
      regex = /#{Regexp.escape settings[:src_pre]}\s+#{type.to_s.singularize}\s+((\S+)\s?(\S+))\s+#{Regexp.escape settings[:src_post]}/
      source.gsub! regex do
        if $2 == settings[:inline]
          assets[$3].to_s
        else
          write $1
        end
      end
  end

  # Replaces all asset tags in source string with asset path or asset source.
  # Writes any referenced assets to disk.
  # @param source [String] code to find and replace asset tags
  # @return [String] copy of `source` with asset tags replaced
  def update_source source
    s = source
    update_source! s
    s
  end
end
