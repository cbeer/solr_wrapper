module SolrWrapper
  class ChecksumValidator
    attr_reader :config

    ALGORITHM = 'sha1'

    def initialize(config)
      @config = config
    end

    def clean!
      path = checksum_path(ALGORITHM)
      FileUtils.remove_entry(path) if File.exist? path
    end

    def validate?(file)
      return true if config.validate == false
      Digest.const_get(ALGORITHM.upcase).file(file).hexdigest == expected_sum(ALGORITHM)
    end

    def validate!(file)
      unless validate? file
        raise "Checksum mismatch" unless config.ignore_checksum
      end
    end

    private

      def checksumurl(suffix)
        "http://archive.apache.org/dist/lucene/solr/#{config.static_config.version}/solr-#{config.static_config.version}.zip.#{suffix}"
      end

      def checksum_path(suffix)
        File.join(config.download_dir, File.basename(checksumurl(suffix)))
      end

      def expected_sum(alg)
        config.checksum || read_file(alg)
      end

      def read_file(alg)
        open(checksumfile(alg)).read.split(" ").first
      end

      def checksumfile(alg)
        path = checksum_path(alg)
        unless File.exist? path
          Downloader.fetch_with_progressbar checksumurl(alg), path
        end
        path
      end
  end
end
