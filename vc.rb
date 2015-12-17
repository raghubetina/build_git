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
      puts "That content is already backed up."
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

  def save_snapshot(snapshot, message)
    destination = "#{SNAPSHOTS_FOLDER}/#{hash(snapshot)}"

    unless object_already_exists?(SNAPSHOTS_FOLDER, destination)
      puts "Creating snapshot."

      snapshot << "\n#{message}\n"
      snapshot << "#{Time.now}\n"

      File.open(destination, "w") { |file| file.write(snapshot) }
    else
      puts "This snapshot has already been created."
    end
  end

  def self.snapshot(message)
    FileUtils.mkdir_p(SNAPSHOTS_FOLDER)

    snapshot = build_snapshot

    save_snapshot(snapshot, message)
  end
end

VC.send(*ARGV)





# Commit
# tree 22d5f1167d016a7354b6bc51f4a8792585dfc936
# parent b49bbfc56985ee7857e51747245de9282fd2ec35
# author Raghu Betina <rbetina@users.noreply.github.com> 1450322784 -0500
# committer Raghu Betina <rbetina@users.noreply.github.com> 1450322784 -0500

# VC can create copies of files with hashes as names.


# Tree
# 040000 tree 67b21f78a4548b2ba3eab318bb3628d039e851e6    app
# 100644 blob 3b18e512dba79e4c8300dd08aeb37f8e728b8dad    readme.md
