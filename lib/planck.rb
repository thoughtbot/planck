# frozen_string_literal: true

require "tempfile"

module Planck
  def self.atomic_write(path, contents, preserve_mode: false)
    dir = File.dirname(path)
    stat = (preserve_mode && File.exist?(path)) ? File.stat(path) : nil

    Tempfile.open(".#{File.basename(path)}", dir) do |tmp|
      tmp.write(contents)
      tmp.flush
      tmp.fsync
      tmp.close

      if stat
        begin
          File.chmod(stat.mode, tmp.path)
        rescue Errno::EPERM, Errno::EACCES
          # If we lack privileges, proceed without preserving.
        end
      end

      File.rename(tmp.path, path)
      File.open(dir, File::RDONLY) { |d| d.fsync }
    end
  end
end
