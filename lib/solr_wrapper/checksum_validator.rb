module SolrWrapper
  class ChecksumValidator
    attr_reader :config

    def initialize(config)
      @config = config
    end

    def clean!
      path = checksum_path(algorithm)
      FileUtils.remove_entry(path) if File.exist? path
    end

    def validate?(file)
      return true if config.validate == false

      actual_sum(file) == expected_sum
    end

    def validate!(file)
      return if validate?(file)

      return if config.ignore_checksum || defined?(JRUBY_VERSION)

      raise "Checksum mismatch: #{file} (expected(#{expected_sum}) != actual(#{actual_sum(file)})"
    end

    private

      def checksumurl(suffix)
        if config.default_download_url == config.static_config.archive_download_url
          "#{config.default_download_url}.#{suffix}"
        else
          "https://archive.apache.org/dist/#{config.mirror_artifact_path}.#{suffix}"
        end
      end

      def checksum_path(suffix)
        File.join(config.download_dir, File.basename(checksumurl(suffix)))
      end

      def actual_sum(file)
        Digest.const_get(algorithm.upcase).file(file).hexdigest
      end

      def expected_sum
        config.checksum || read_file(algorithm)
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

      def algorithm
        return config.static_config.algorithm if config.static_config.algorithm
        return 'sha1' if config.static_config.version =~ /^[1-6]/ || config.static_config.version =~ /^[7]\.[0-4]/

        'sha512'
      end
  end
end
