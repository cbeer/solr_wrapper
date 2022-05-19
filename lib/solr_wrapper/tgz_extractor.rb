require 'rubygems/package'
require 'zlib'

module SolrWrapper
  class TgzExtractor
    attr_reader :file, :destination

    TAR_LONGLINK = '././@LongLink'

    def initialize(file, destination: nil)
      @file = file
      @destination = destination || Dir.mktmpdir
    end

    def extract!
      Gem::Package::TarReader.new(Zlib::GzipReader.open(file)) do |tar|
        dest = nil
        tar.each do |entry|
          if entry.full_name == TAR_LONGLINK
            dest = File.join destination, entry.read.strip
            next
          end
          dest ||= File.join destination, entry.full_name
          if entry.directory?
            File.delete dest if File.file? dest
            FileUtils.mkdir_p dest, mode: entry.header.mode, verbose: false
          elsif entry.file?
            FileUtils.rm_rf dest if File.directory? dest
            File.open dest, 'wb' do |f|
              f.print entry.read
            end
            FileUtils.chmod entry.header.mode, dest, verbose: false
          elsif entry.header.typeflag == '2' # Symlink!
            File.symlink entry.header.linkname, dest
          end
          dest = nil
        end
      end
    rescue StandardError => e
      abort "Unable to extract #{file} into #{destination}: #{e.message}"
    end
  end
end
