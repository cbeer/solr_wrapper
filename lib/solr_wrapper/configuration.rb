require 'faraday'

module SolrWrapper
  class Configuration
    attr_reader :options

    def initialize(options = {})
      @config = options[:config]
      @verbose = options[:verbose]

      @options = load_configs(Array(options[:config])).merge(options)
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

    def ignore_md5sum
      options[:ignore_md5sum]
    end

    def md5sum
      options[:md5sum]
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

    def solr_zip_path
      options[:solr_zip_path]
    end

    def download_dir
      options[:download_dir] || default_download_dir
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
        config_version = options.fetch(:version, SolrWrapper.default_instance_options[:version])
        if config_version == 'latest'
          fetch_latest_version
        else
          config_version
        end
      end
    end

    def mirror_url
      "http://www.apache.org/dyn/closer.lua/lucene/solr/#{version}/solr-#{version}.zip?asjson=true"
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
      Configuration.slice(convert_keys(hash), :name, :dir, :persist)
    end

    def configsets
      configsets = options[:configsets] || []
      configsets.map { |x| convert_keys(x) }
    end

    def poll_interval
      options.fetch(:poll_interval, 1)
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
        convert_keys(config)
      end

      def convert_keys(hash)
        hash.each_with_object({}) { |(k, v), h| h[k.to_sym] = v }
      end

      def default_configuration_paths
        ['~/.solr_wrapper.yml', '~/.solr_wrapper', '.solr_wrapper.yml', '.solr_wrapper']
      end

      def fetch_latest_version
        path = 'https://svn.apache.org/repos/asf/lucene/cms/trunk/content/latestversion.mdtext'
        Faraday.get(path).body.strip
      rescue Faraday::ConnectionFailed
        $stderr.puts "Unable to connect to #{path} to retrieve the latest version. Using a default"
        SolrWrapper.fallback_solr_version
      end
  end
end
