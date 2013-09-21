require 'open3'
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

  # Default {#options}.
  DEFAULT_OPTIONS = {
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

  # @!attribute options
  #   @return [Hash] options (merged with {DEFAULT_OPTIONS}}.
  #
  # @!attribute directory
  #   @return [String] directory which all paths will be relative to if set
  #
  # @!attribute paths
  #   @return [Array] paths to load into sprockets environment
  #
  # @!attribute type
  #   @return [Symbol] type of asset
  attr_reader :options
  attr_accessor :directory, :paths, :type

  def initialize directory: '', options: {}, paths: {}
    self.options = options
    self.directory = directory
    self.paths = paths
  end

  def options= options
    @options ||= DEFAULT_OPTIONS
    @options = @options.merge options
  end

  # @return [Sprockets::Environment] the current sprockets environment
  def sprockets
    @sprockets ||= Sprockets::Environment.new
  end

  # Load options into the sprockets environment.
  # Values are loaded from {#options}.
  def load_options
    options[:sprockets_options].each do |opt|
      sprockets.send "#{opt}=".to_sym, options[opt] if options[opt]
    end
  end

  # Load paths into the sprockets environment.
  # Values are loaded from {#paths}.
  def load_paths
    paths.each do |path|
      sprockets.append_path "#{directory + '/' unless directory.empty?}#{path}"
    end
  end

  # @return [Sprockets::Environment] sprockets environment with {#options} and {#paths} loaded
  def assets
    unless @loaded
      load_options
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
  def write target, path: options[:output], gzip: options[:gzip]
    asset = assets[target]

    return if asset.nil?

    logical_path = asset.logical_path.to_s
    extname = File.extname logical_path
    hashed_name = "#{logical_path.chomp extname}-#{asset.digest}#{File.extname logical_path}"

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
      regex = /#{Regexp.escape options[:src_pre]}\s+#{type.to_s.singularize}\s+((\S+)\s?(\S+))\s+#{Regexp.escape options[:src_post]}/
      source.gsub! regex do
        if $2 == options[:inline]
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

  # Scans all non-binary files under `path` ({#directory} by default) for asset tags.
  # Uses current asset {#type} (if set) and {#options}.
  # @param path [String] where to look for source files
  # @return [Array] files with asset tags
  def find_tags path: directory
    self.class.find_tags path, type, options
  end

  # Scans all non-binary files under `path` for asset tags.
  # @param path [String] where to look for source files
  # @param type [String, nil] only look for asset tags with this type (or any type if `nil`)
  # @param options [Hash] merged with {DEFAULT_OPTIONS}
  # (see #find_tags)
  def self.find_tags path, type=nil, options={}
    raise ArgumentError, 'path cannot be empty' if path.empty?

    options = DEFAULT_OPTIONS.merge options
    pre = Regexp.escape options[:src_pre]
    post= Regexp.escape options[:src_post]

    cmd = [ 'grep' ]
    cmd.concat [ '-l', '-I', '-r', '-E' ]
    cmd << \
      if type.nil?
        pre + '(\s+(\w|\s)+?)' + post
      else
        pre + '(\s+' + type.to_s + '\s+(\w|\s)+?)' + post
      end
    cmd << path

    files = []
    Open3.popen2(*cmd) { |_, stdout| stdout.gets.each_line { |l| files << l.chomp } }
    files
  end
end
