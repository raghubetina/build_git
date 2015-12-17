require "fileutils"
require "digest/sha1"

class VC
  CONTENT_ROOT_FOLDER = "app"
  BACKUPS_FOLDER = "vc_backups"
  SNAPSHOTS_FOLDER = "vc_snapshots"
  NAMES_FOLDER = "vc_names"
  CURRENT_SNAP = "current_snap"

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

      if current_snapshot
        snapshot_body << "\n#{current_snapshot}\n"
      else
        snapshot_body << "\n\n"
      end

      snapshot_body << "#{message}\n#{Time.now}\n"

      File.open(destination, "w") { |file| file.write(snapshot_body) }
    else
      puts "This snapshot has already been created."
    end

    set_current_snap(destination)
  end

  def self.set_current_snap(snapshot)
    File.open(CURRENT_SNAP, "w") { |file| file.write(snapshot) }
  end

  def self.snapshot(message)
    FileUtils.mkdir_p(SNAPSHOTS_FOLDER)

    snapshot_body = build_snapshot

    save_snapshot(snapshot_body, message) if snapshot_body
  end

  def self.restore(snapshot)
    lines = File.readlines(snapshot)

    puts "Snapping to #{snapshot}"

    files = lines[0..-5]
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
    if matches.any?
      return matches.first
    end
  end

  def self.find_snapshot(identifier)
    if File.file?(identifier)
      return identifier
    elsif snapshot = find_snapshot_by_hash(identifier)
      return snapshot
    elsif snapshot = find_snapshot_by_name(identifier)
      return File.read(snapshot)
    end
  end

  def self.snap(identifier)
    if snapshot = find_snapshot(identifier)
      restore(snapshot)
    else
      puts "Couldn't find that snapshot."
      return
    end

    set_current_snap(identifier)
  end

  def self.name(hash, name)
    if snapshot = find_snapshot_by_hash(hash)
      FileUtils.mkdir_p(NAMES_FOLDER)

      destination = "#{NAMES_FOLDER}/#{name}"

      File.open(destination, "w") { |file| file.write(snapshot) }
    end
  end

  def self.where
    if File.file?(CURRENT_SNAP)
      puts contents(CURRENT_SNAP)
    else
      puts "Haven't snapped anywhere yet."
    end
  end

  def self.current_snapshot
    if File.file?(CURRENT_SNAP)
      current_snap = File.read(CURRENT_SNAP)
      type, identifier = current_snap.split("/")

      case type
      when "vc_snapshots"
        return current_snap
      when "vc_names"
        return contents(current_snap)
      end
    end
  end

  def self.parent(identifier)
    if snapshot = find_snapshot(identifier)
      lines = File.readlines(snapshot)
      parent = lines[-3].chomp
      if parent != ""
        return parent
      end
    end
  end

  def self.ancestry(snapshot)
    if parent = parent(snapshot)
      return ancestry(parent) << parent
    else
      return []
    end
  end

  def self.history
    ancestry(current_snapshot).reverse.each do |ancestor|
      lines = File.readlines(ancestor)
      puts ancestor
      puts "Date: #{lines[-1]}"
      puts "Message: #{lines[-2]}"
      puts
    end
  end
end

VC.send(*ARGV)
