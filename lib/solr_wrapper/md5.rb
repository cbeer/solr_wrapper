module SolrWrapper
  class MD5
    attr_reader :config
    def initialize(config)
      @config = config
    end

    def clean!
      FileUtils.remove_entry(config.md5sum_path) if File.exist? config.md5sum_path
    end

    def validate?(file)
      return true if config.validate == false

      Digest::MD5.file(file).hexdigest == expected_sum
    end

    def validate!(file)
      unless validate? file
        raise "MD5 mismatch" unless config.ignore_md5sum
      end
    end

    private

      def expected_sum
        @md5sum ||= config.md5sum
        @md5sum ||= read_file
      end

      def read_file
        open(md5file).read.split(" ").first
      end

      def md5file
        unless File.exist? config.md5sum_path
          Downloader.fetch_with_progressbar config.md5url, config.md5sum_path
        end

        config.md5sum_path
      end
  end
end
