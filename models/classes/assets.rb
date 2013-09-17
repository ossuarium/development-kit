require 'sprockets'

class Kit::Bit::Assets

  # Allowed settings for Sprockets::Environment.
  SPROCKETS_CFG = [ :js_compressor, :css_compressor ]

  attr_accessor :directory, :settings, :paths

  def initialize directory: nil, settings: nil, paths: nil
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
    end if settings
  end

  # Load paths into the sprockets environment.
  # Values are loaded from @paths.
  def load_paths
    paths.each do |path|
      path = "#{directory + "/" if directory}#{path}"
      sprockets.append_path Kit::Bit::Utility.validate_path(path, directory)
    end if paths
  end

  # @return [Sprockets::Environment] sprockets environment with settings and paths loaded
  def assets
    load_settings
    load_paths
    sprockets
  end
end
