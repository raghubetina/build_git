require "fileutils"

class VC
  def self.version_folder_names
    Dir.glob("*").select do |object|
      object.start_with?("version") && File.directory?(object)
    end
  end

  def self.version_numbers
    version_folder_names.map do |version_folder_name|
      version_folder_name.split('_').last.to_i
    end
  end

  def self.last_version
    version_numbers.sort.last
  end

  def self.next_version
    last_version + 1
  end

  def self.add
    FileUtils.copy_entry "app", "version_#{next_version}/"
  end
end

VC.send(ARGV[0])
