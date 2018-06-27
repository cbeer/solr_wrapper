module SolrWrapper
  class Checksum
    attr_reader :config
    def initialize(config)
      @config = config
    end

    def clean!
      FileUtils.remove_entry(config.checksum_path) if File.exist? config.checksum_path
    end

    def validate?(file)
      return true if config.validate == false

      digest = case config.checksum_type
               when 'md5'
                 Digest::MD5.file(file).hexdigest
               else
                 Digest::SHA1.file(file).hexdigest
               end

      digest == expected_sum
    end

    def validate!(file)
      unless validate? file
        raise "Checksum mismatch" unless config.ignore_checksum
      end
    end

    private

      def expected_sum
        @expected_sum ||= config.checksum
        @expected_sum ||= read_file
      end

      def read_file
        open(checksum_file).read.split(" ").first
      end

      def checksum_file
        unless File.exist? config.checksum_path
          Downloader.fetch_with_progressbar config.checksum_url, config.checksum_path
        end

        config.checksum_path
      end
  end
end
