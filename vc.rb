require "fileutils"
require "digest/sha1"

class VC
  def self.files
    Dir.glob("app/**/*").select { |object| File.file?(object) }
  end

  def self.hash(string)
    Digest::SHA1.hexdigest(string)
  end

  def self.contents(file)
    open(file).read
  end

  def self.object_already_exists?(filename)
    Dir.glob("vc_objects/*").include?(filename)
  end

  def self.create_file_object(file)
    destination = "vc_objects/#{hash(contents(file))}"

    unless object_already_exists?(destination)
      puts "Backing up content."
      FileUtils.copy(file, destination)
    else
      puts "That content is already backed up."
    end
  end

  def self.add
    FileUtils.mkdir_p("vc_objects")

    files.each { |file| create_file_object(file) }
  end
end

VC.send(ARGV[0])
