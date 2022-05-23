require 'minitar'
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
      Minitar.unpack(Zlib::GzipReader.open(file), destination)
    rescue StandardError => e
      abort "Unable to extract #{file} into #{destination}: #{e.message}"
    end
  end
end
