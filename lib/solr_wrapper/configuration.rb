require 'faraday'
require 'faraday/follow_redirects'

module SolrWrapper
  class Configuration
    attr_reader :options

    def initialize(options = {})
      @config = options[:config]
      @verbose = options[:verbose]

      @options = load_configs(Array(options[:config])).merge(options)
      @options[:env] ||= ENV
    end

    def solr_xml
      options[:solr_xml]
    end

    def extra_lib_dir
      options[:extra_lib_dir]
    end

    def validate
      options[:validate]
    end

    def ignore_checksum
      options[:ignore_checksum]
    end

    def checksum
      options[:checksum]
    end

    def algorithm
      options[:algorithm]
    end

    def url
      options[:url]
    end

    def port
      # Check if the port option has been explicitly set to nil.
      # this means to start solr wrapper on a random open port
      return nil if options.key?(:port) && !options[:port]
      options.fetch(:port) { SolrWrapper.default_instance_options[:port] }.to_s
    end

    def zookeeper_host
      options[:zookeeper_host]
    end

    def zookeeper_port
      options[:zookeeper_port]
    end

    def artifact_path
      options[:artifact_path]
    end

    def download_dir
      env_options[:download_dir] || options[:download_dir] || default_download_dir
    end

    def default_download_dir
      if defined?(Rails) && Rails.respond_to?(:root) && Rails.root
        File.join(Rails.root, 'tmp')
      else
        Dir.tmpdir
      end
    end

    def solr_options
      options.fetch(:solr_options, {})
    end

    def env
      options.fetch(:env, {})
    end

    def instance_dir
      options[:instance_dir]
    end

    def version
      @version ||= begin
        config_version = if env_options[:version].nil? || env_options[:version].empty?
          options.fetch(:version, SolrWrapper.default_instance_options[:version])
        else
          env_options[:version]
        end

        if config_version == 'latest'
          fetch_latest_version
        else
          config_version
        end
      end
    end

    def mirror_artifact_path
      if version > '9'
        "solr/solr/#{version}/solr-#{version}.tgz"
      else
        "lucene/solr/#{version}/solr-#{version}.tgz"
      end
    end

    def closest_mirror_url
      "https://www.apache.org/dyn/closer.lua/#{mirror_artifact_path}?asjson=true"
    end

    def mirror_url
      @mirror_url ||= if options[:mirror_url]
        options[:mirror_url] + mirror_artifact_path
      else
        begin
          client = Faraday.new(closest_mirror_url) do |faraday|
            faraday.use Faraday::FollowRedirects::Middleware
            faraday.adapter Faraday.default_adapter
          end

          json = client.get.body
          doc = JSON.parse(json)
          url = doc['preferred'] + doc['path_info']

          response = Faraday.head(url)

          if response.success?
            url
          else
            archive_download_url
          end
        rescue Errno::ECONNRESET, SocketError, Faraday::Error
          archive_download_url
        end
      end
    end

    def archive_download_url
      "https://archive.apache.org/dist/#{mirror_artifact_path}"
    end

    def cloud
      options[:cloud]
    end

    def verbose?
      @verbose || (options && !!options.fetch(:verbose, false))
    end

    def version_file
      options[:version_file]
    end

    def collection_options
      hash = options.fetch(:collection, {})
      Configuration.slice(hash.transform_keys(&:to_sym), :name, :dir, :persist)
    end

    def configsets
      configsets = options[:configsets] || []
      configsets.map { |x| x.transform_keys(&:to_sym) }
    end

    def poll_interval
      options.fetch(:poll_interval, 1)
    end

    def contrib
      options.fetch(:contrib, [])
    end

    private

      def self.slice(source, *keys)
        keys.each_with_object({}) { |k, hash| hash[k] = source[k] if source.has_key?(k) }
      end

      def load_configs(config_files)
        config = {}

        (default_configuration_paths + config_files.compact).each do |p|
          path = File.expand_path(p)
          next unless File.exist? path
          config.merge!(read_config(path))
        end

        config
      end

      def read_config(config_file)
        $stdout.puts "Loading configuration from #{config_file}" if verbose?
        config = YAML.load(ERB.new(IO.read(config_file)).result(binding))
        unless config
          $stderr.puts "Unable to parse config #{config_file}" if verbose?
          return {}
        end

        config.transform_keys!(&:to_sym)
        absoluteize_paths(config, root: File.dirname(config_file))
      end

      def absoluteize_paths(config, root: Dir.pwd)
        return config unless config[:contrib]

        config = config.dup

        config[:contrib] = config[:contrib].map do |mapping|
          mapping = mapping.transform_keys(&:to_sym)
          mapping[:from] = File.expand_path(mapping[:from], root)
          mapping[:to] ||= 'contrib/'
        end

        config
      end

      def default_configuration_paths
        ['~/.solr_wrapper.yml', '~/.solr_wrapper', '.solr_wrapper.yml', '.solr_wrapper']
      end

      def fetch_latest_version
        url = options.fetch(:latest_version_url, 'https://solr.apache.org/downloads.html')

        client = Faraday.new(url) do |faraday|
          faraday.use Faraday::FollowRedirects::Middleware
          faraday.adapter Faraday.default_adapter
        end

        response = client.get
        response.body.to_s[/Solr \d+\.\d+\.\d+/][/\d+\.\d+\.\d+/]
      end

      def env_options
        @env_options ||= begin
          env = options.fetch(:env, {})
          {
            download_dir: env['SOLR_WRAPPER_DOWNLOAD_DIR'],
            version: env['SOLR_WRAPPER_SOLR_VERSION']
          }
        end
      end
  end
end
