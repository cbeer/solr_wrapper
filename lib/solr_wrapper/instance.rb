require 'digest'
require 'fileutils'
require 'json'
require 'open-uri'
require 'ruby-progressbar'
require 'securerandom'
require 'stringio'
require 'tmpdir'
require 'zip'

module SolrWrapper
  class Instance
    attr_reader :options

    ##
    # @param [Hash] options
    # @option options [String] :url
    # @option options [String] :version
    # @option options [String] :port
    # @option options [String] :version_file
    # @option options [String] :instance_dir
    # @option options [String] :download_path
    # @option options [String] :md5sum
    # @option options [Boolean] :verbose
    # @option options [Boolean] :managed
    # @option options [Boolean] :ignore_md5sum
    def initialize options = {}
      @options = options
    end

    def wrap &block
      start
      yield self
    ensure
      stop
    end

    ##
    # Start Solr and wait for it to become available
    def start
      extract
      if managed?
        exec('start', p: port)

        # Wait for solr to start
        unless status
          sleep 1
        end
      end
    end

    ##
    # Stop Solr and wait for it to finish exiting
    def stop
      if managed? and started?

        exec('stop', p: port)
        # Wait for solr to stop
        while status
          sleep 1
        end
      end
    end

    ##
    # Check the status of a managed Solr service
    def status
      return true unless managed?

      out = exec('status', output: true).read
      out =~ /running on port #{port}/
    end

    ##
    # Is Solr running?
    def started?
      !!status
    end

    ##
    # Create a new collection in solr
    # @param [Hash] options
    # @option options [String] :name
    # @option options [String] :dir
    def create options = {}
      options[:name] ||= SecureRandom.hex

      exec("create", c: options[:name], d: options[:dir], p: port)

      options[:name]
    end
    
    ##
    # Create a new collection in solr
    # @param [String] name collection name
    def delete name, options = {}
      exec("delete", c: name, p: port)
    end

    ##
    # Create a new collection, run the block, and then clean up the collection
    # @param [Hash] options
    # @option options [String] :name
    # @option options [String] :dir
    def with_collection options = {}
      name = create(options)
      begin
        yield name
      ensure
        delete name
      end
    end

    ##
    # Get the port this Solr instance is running at 
    def port
      options.fetch(:port, "8983").to_s
    end

    ##
    # Clean up any files solr_wrapper may have downloaded
    def clean!
      stop
      FileUtils.remove_entry(download_path) if File.exists? download_path
      FileUtils.remove_entry(tmp_save_dir, true) if File.exists? tmp_save_dir
      FileUtils.remove_entry(instance_dir, true) if File.exists? instance_dir
      FileUtils.remove_entry(md5sum_path) if File.exists? md5sum_path
      FileUtils.remove_entry(version_file) if File.exists? version_file
    end

    protected
    def extract
      return solr_dir if File.exists?(solr_binary) and extracted_version == version

      zip_path = download

      begin
        Zip::File.open(zip_path) do |zip_file|
          # Handle entries one by one
          zip_file.each do |entry|
            dest_file = File.join(tmp_save_dir,entry.name)
            FileUtils.remove_entry(dest_file,true)
            entry.extract(dest_file)
          end
        end

      rescue Exception => e
        abort "Unable to unzip #{zip_path} into #{tmp_save_dir}: #{e.message}"
      end

      begin  
        FileUtils.remove_dir(solr_dir,true)
        FileUtils.cp_r File.join(tmp_save_dir, File.basename(default_url, ".zip")), solr_dir
        self.extracted_version = version
        FileUtils.chmod 0755, solr_binary
      rescue Exception => e
        abort "Unable to copy #{tmp_save_dir} to #{solr_dir}: #{e.message}"
      end

      solr_dir
    ensure
      FileUtils.remove_entry tmp_save_dir if File.exists? tmp_save_dir
    end

    def download
      unless File.exists? download_path and validate? download_path
        fetch_with_progressbar url, download_path
        validate! download_path
      end

      download_path
    end

    def validate? file
      Digest::MD5.file(file).hexdigest == expected_md5sum
    end

    def validate! file
      unless validate? file
        raise "MD5 mismatch" unless options[:ignore_md5sum]
      end
    end

    ##
    # Run a bin/solr command
    # @see https://github.com/apache/lucene-solr/blob/trunk/solr/bin/solr
    def exec cmd, options = {}
      output = !!options.delete(:output)
      args = [solr_binary, cmd] + options.map { |k,v| ["-#{k}", "#{v}"] }.flatten

      if IO.respond_to? :popen4
        # JRuby
        pid, input, output, error = IO.popen4(args.join(" "))
        
        stringio = StringIO.new
        if verbose? and !output
          IO.copy_stream(output,$stderr)
          IO.copy_stream(error,$stderr)
        else
          IO.copy_stream(output, stringio)
          IO.copy_stream(error, stringio)
        end
        input.close
        output.close
        error.close
        
        stringio.rewind

        if $? != 0
          raise "Failed to execute solr #{cmd}: #{stringio.read}"
        end

        stringio
      else
        IO.popen(args + [err: [:child, :out]]) do |io|
          stringio = StringIO.new
          if verbose? and !output
            IO.copy_stream(io,$stderr)
          else
            IO.copy_stream(io, stringio)
          end
          _, exit_status = Process.wait2(io.pid)

          stringio.rewind

          if exit_status != 0
            raise "Failed to execute solr #{cmd}: #{stringio.read}"
          end

          stringio
        end
      end
    end

    private  
    def url
      @download_url ||= options.fetch(:url, default_url)
    end

    def default_url
      @default_url ||= begin
        mirror_url = "http://www.apache.org/dyn/closer.cgi/lucene/solr/#{version}/solr-#{version}.zip?asjson=true"
        json = open(mirror_url).read
        doc = JSON.parse(json)
        doc['preferred'] + doc['path_info']
      end
    end

    def md5url
      "http://www.us.apache.org/dist/lucene/solr/#{version}/solr-#{version}.zip.md5"
    end

    def version
      @version ||= options.fetch(:version, default_solr_version)
    end

    def default_solr_version
      SolrWrapper.default_solr_version
    end

    def download_path
      @download_path ||= options.fetch(:download_path, default_download_path)  
    end

    def default_download_path
      File.join(Dir.tmpdir, File.basename(default_url))
    end

    def solr_dir
      @solr_dir ||= options.fetch(:instance_dir, File.join(Dir.tmpdir, File.basename(default_url, ".zip")))
    end

    def verbose?
      !!options.fetch(:verbose, false)
    end

    def managed?
      !!options.fetch(:managed, true)
    end

    def version_file
      options.fetch(:version_file, File.join(solr_dir, "VERSION"))
    end

    def expected_md5sum
      @md5sum ||= options.fetch(:md5sum, open(md5file).read.split(" ").first)
    end
    
    def solr_binary
      File.join(solr_dir, "bin", "solr")
    end

    def md5sum_path
      File.join(Dir.tmpdir, File.basename(md5url))
    end

    def tmp_save_dir
      @tmp_save_dir ||= Dir.mktmpdir
    end

    def fetch_with_progressbar url, output
      pbar = ProgressBar.create(title: File.basename(url), total: nil, format: "%t: |%B| %p%% (%e )")
      open(url, content_length_proc: lambda {|t|
        if t && 0 < t
          pbar.total = t
        end
        },
        progress_proc: lambda {|s|
          pbar.progress = s
        }) do |io|
        IO.copy_stream(io,output)
      end
    end

    def md5file
      unless File.exists? md5sum_path
        fetch_with_progressbar md5url, md5sum_path
      end

      md5sum_path
    end

    def extracted_version
      File.read(version_file).strip if File.exists? version_file
    end

    def extracted_version= version
      File.open(version_file, "w") do |f|
        f.puts version
      end
    end
  end
end