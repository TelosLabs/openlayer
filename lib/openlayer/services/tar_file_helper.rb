require 'rubygems/package'
require 'fileutils'
require 'zlib'

module Openlayer
  class TarFileHelper

    def self.create_tar_from_folders(folders, tar_file_name)
      File.open(tar_file_name, 'wb') do |file|
        Gem::Package::TarWriter.new(file) do |tar|
          folders.each do |folder|
            base_name = File.basename(folder)
            add_directory_to_tar(tar, folder, base_name)
          end
        end
      end
    end

    def self.validate_structure(file_path, required_structure)
      tarfile_structure = []
      begin
        Gem::Package::TarReader.new(Zlib::GzipReader.open(file_path)).each do |entry|
          tarfile_structure << entry.full_name
        end
      rescue Zlib::GzipFile::Error => e
        stacktrace = e.backtrace.join("\n")
        LOGGER.error("ERROR: #{e.message}\n #{stacktrace}")
        return nil
      end

      REQUIRED_TARFILE_STRUCTURE.each do |required_file|
        raise Error, "Missing file: #{required_file}" unless tarfile_structure.include?(required_file)
      end
    end

    private

    def self.add_directory_to_tar(tar, folder, base_name)
      Dir[File.join(folder, '**/*')].each do |file|
        mode = File.stat(file).mode
        relative_file = File.join(base_name, file.sub(folder + '/', ''))

        if File.directory?(file)
          tar.mkdir(relative_file, mode)
        else
          tar.add_file_simple(relative_file, mode, File.size(file)) do |io|
            File.open(file, 'rb') { |f| io.write(f.read) }
          end
        end
      end
    end
  end
end