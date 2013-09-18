require 'sprockets'

class Kit::Bit::Assets

  # Allowed settings for Sprockets::Environment.
  SPROCKETS_CFG = [ :js_compressor, :css_compressor ]

  attr_accessor :directory, :settings, :paths

  def initialize directory: '', settings: {}, paths: {}
    self.directory = directory
    self.settings = settings
    self.paths = paths
  end

  # @return [Sprockets::Environment]
  def sprockets
    @sprockets ||= Sprockets::Environment.new
  end

  # Load settings into the sprockets environment.
  # Values are loaded from @settings.
  def load_settings
    SPROCKETS_CFG.each do |cfg|
      sprockets.send "#{cfg}=".to_sym, settings[cfg] if settings[cfg]
    end
  end

  # Load paths into the sprockets environment.
  # Values are loaded from @paths.
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

  def write target, path: '', compress: false
    asset = assets[target]

    if path.empty?
      path = directory
    elsif ! directory.empty?
      path = "#{directory}/#{path}"
    end unless path =~ /^\//

    path += '/' unless path.empty?
    path += Kit::Bit::Utility.hash_name asset.logical_path.to_s, asset.to_s

    if compress
      asset.write_to path, compress: true
    else
      asset.write_to path
    end
  end
end
