module FileUtils
  def self.rm_rf(path)
    if File.directory?(path)
      Dir.each_child(path) do |entry|
        entry_path = File.join(path, entry)
        if File.file?(entry_path)
          File.unlink(entry_path)
        elsif File.directory?(entry_path)
          rm_rf(entry_path)
        end
      end
      Dir.rmdir(path)
    elsif File.file?(path)
      File.unlink(path)
    end
  end

  def self.mkdir_p(path, mode: nil)
    parts = File.expand_path(path).split(File::SEPARATOR)

    mkdir = lambda do |dir, *args|
      Dir.mkdir(dir, *args)
    rescue # rubocop:disable Style/RescueStandardError
      raise unless File.directory?(dir)
    end

    dir = parts.shift
    parts.each do |part|
      dir = File.join(dir, part)

      unless File.directory?(dir)
        if mode
          mkdir.(dir, mode)
          # mkdir(2) (and thus Ruby's Dir.mkdir) does some masking of the mode,
          # and thus the passed mode above in many cases doesn't have the desired
          # affect. So we call chmod here to set the mode as desired.
          File.chmod(mode, dir)
        else
          mkdir.(dir)
        end
      end
    end
  end
end
