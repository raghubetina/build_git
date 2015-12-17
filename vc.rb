require "fileutils"
require "digest/sha1"

class VC
  CONTENT_ROOT_FOLDER = "app"
  BACKUPS_FOLDER = "vc_backups"
  SNAPSHOTS_FOLDER = "vc_snapshots"
  NAMES_FOLDER = "vc_names"

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
    snapshot_body = ""

    files.each do |file|
      destination = "#{BACKUPS_FOLDER}/#{hash(contents(file))}"

      if object_already_exists?(BACKUPS_FOLDER, destination)
        snapshot_body << "#{destination}    #{file}\n"
      else
        puts "You have unsaved changes in #{file}. Please back them up before taking a snapshot."
        return
      end
    end

    return snapshot_body
  end

  def self.save_snapshot(snapshot_body, message)
    destination = "#{SNAPSHOTS_FOLDER}/#{hash(snapshot_body)}"

    unless object_already_exists?(SNAPSHOTS_FOLDER, destination)
      puts "Creating snapshot."

      snapshot_body << "\n#{message}\n#{Time.now}\n"

      File.open(destination, "w") { |file| file.write(snapshot_body) }
    else
      puts "This snapshot has already been created."
    end
  end

  def self.snapshot(message)
    FileUtils.mkdir_p(SNAPSHOTS_FOLDER)

    snapshot_body = build_snapshot

    save_snapshot(snapshot_body, message) if snapshot_body
  end

  def self.restore(snapshot)
    lines = File.readlines(snapshot)

    puts "Snapping to #{snapshot}"

    files = lines[0..-4]
    files.each do |file|
      object, destination = file.split
      FileUtils.copy(object, destination)
    end

    message = lines[-2].strip
    time = lines[-1].strip
    puts "Now at '#{message}' [#{time}]"
  end

  def self.find_snapshot_by_hash(hash)
    matches = Dir.glob("#{SNAPSHOTS_FOLDER}/#{hash}*")
    if matches.empty?
      return
    elsif matches.count > 1
      puts "Multiple matches found. Please be more specific."
      return
    else
      return matches.first
    end
  end

  def self.find_snapshot_by_name(name)
    matches = Dir.glob("#{NAMES_FOLDER}/#{name}")
    if matches.empty?
      return
    else
      return matches.first
    end
  end

  def self.snap(snapshot_identifier)
    if snapshot = find_snapshot_by_hash(snapshot_identifier)
      restore(snapshot)
    elsif snapshot = find_snapshot_by_name(snapshot_identifier)
      restore(File.read(snapshot))
    else
      puts "Couldn't find that snapshot."
    end
  end

  def self.name(hash, name)
    if snapshot = find_snapshot_by_hash(hash)
      FileUtils.mkdir_p(NAMES_FOLDER)

      destination = "#{NAMES_FOLDER}/#{name}"

      File.open(destination, "w") { |file| file.write(snapshot) }
    end
  end
end

VC.send(*ARGV)
