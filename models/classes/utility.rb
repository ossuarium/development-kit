require 'archive/tar/minitar'

# Utility functions for this kit.
class Kit::Bit::Utility

  protected

  # Make a random directory.
  # @param [String] root directory to place random directory
  # @param [String] prefix prepended to random directory name
  # @param [String, nil] dir the random directory name (used recursively)
  # @return [String] path to created random directory
  def self.make_random_directory root, prefix, dir = nil
    path = "#{root}/#{prefix}#{dir}" unless dir.nil?
    if path.nil? or File.exists? path
      make_random_directory root, prefix, Random.rand(10000000)
    else
      FileUtils.mkdir(path).first
    end
  end

  # Checks that a path is really rooted under a given root directory.
  # Forbids use of '../' and '~/' in path.
  # @param [String] path
  # @param [String] root directory where path should be rooted under
  # @return [String] input path if valid
  def self.validate_path path, root=nil
    root = '' if root.nil?
    case
    when path[/(\.\.\/|~\/)/] then raise RuntimeError
    when File.expand_path(path, root)[/^#{root}/].nil? then raise RuntimeError
    else path
    end
  end

  # Extracts a git repo to a directory.
  # @param [Grit::Repo] repo
  # @param [String] treeish
  # @param [String] directory
  def self.extract_repo repo, treeish, directory, files: nil
    input = Archive::Tar::Minitar::Input.new StringIO.new(repo.archive_tar treeish)
    input.each do |entry|
      if files.nil?
        input.extract_entry directory, entry
      else
        input.extract_entry directory, entry if files.include? entry.name
      end
    end
  end
end
