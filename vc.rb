require "fileutils"
require "digest/sha1"

class VC
  CONTENT_ROOT_FOLDER = "app"
  BACKUPS_FOLDER = "vc_backups"
  SNAPSHOTS_FOLDER = "vc_snapshots"

  def self.files
    Dir.glob("#{CONTENT_ROOT_FOLDER}/**/*").select do |object|
      File.file?(object)
    end
  end

  def self.hash(string)
    Digest::SHA1.hexdigest(string)
  end

  def self.contents(file)
    open(file).read
  end

  def self.object_already_exists?(folder, filename)
    Dir.glob("#{folder}/*").include?(filename)
  end

  def self.create_version(file)
    destination = "#{BACKUPS_FOLDER}/#{hash(contents(file))}"

    unless object_already_exists?(BACKUPS_FOLDER, destination)
      puts "Backing up #{file}"
      FileUtils.copy(file, destination)
    else
      puts "#{file} is already backed up."
    end
  end

  def self.backup
    FileUtils.mkdir_p(BACKUPS_FOLDER)

    files.each { |file| create_version(file) }
  end

  def self.build_snapshot
    commit = ""

    files.each do |file|
      destination = "#{BACKUPS_FOLDER}/#{hash(contents(file))}"

      if object_already_exists?(BACKUPS_FOLDER, destination)
        commit << "#{destination}    #{file}\n"
      else
        puts "You have unsaved changes in #{file}. Please back them up before taking a snapshot."
        return
      end
    end

    return commit
  end

  def self.save_snapshot(snapshot, message)
    destination = "#{SNAPSHOTS_FOLDER}/#{hash(snapshot)}"

    unless object_already_exists?(SNAPSHOTS_FOLDER, destination)
      puts "Creating snapshot."

      snapshot << "\n#{message}\n#{Time.now}\n"

      File.open(destination, "w") { |file| file.write(snapshot) }
    else
      puts "This snapshot has already been created."
    end
  end

  def self.snapshot(message)
    FileUtils.mkdir_p(SNAPSHOTS_FOLDER)

    snapshot = build_snapshot

    save_snapshot(snapshot, message) if snapshot
  end

  def self.snap(hash)
    matches = Dir.glob("#{SNAPSHOTS_FOLDER}/#{hash}*")
    if matches.empty?
      puts "Couldn't find that snapshot."
    elsif matches.count > 1
      puts "Multiple matches found. Please be more specific."
    else
      puts contents(matches.first)
    end
  end
end

VC.send(*ARGV)
