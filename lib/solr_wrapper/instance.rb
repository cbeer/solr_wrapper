require 'digest'
require 'fileutils'
require 'open-uri'
require 'ruby-progressbar'
require 'securerandom'
require 'stringio'
require 'tmpdir'
require 'zip'

module SolrWrapper
  class Instance
    attr_reader :options

    def initialize options = {}
      @options = options
    end

    def wrap &block
      start
      yield self
    ensure
      stop
    end

    def start
      extract
      IO.popen([solr_binary, "start", "-p", port, err: [:child, :out]]) do |io|
        stringio = StringIO.new
        if verbose?
          IO.copy_stream(io,$stderr)
        else
          IO.copy_stream(io, stringio)
        end
        _, exit_status = Process.wait2(io.pid)
        if exit_status != 0
          stringio.rewind
          raise "Unable to start solr: #{stringio.read}"
        end
      end if managed?

      # Wait for solr to start
      unless status
        sleep 1
      end
      started!
    end

    def stop
      return unless started?

      IO.popen([solr_binary, "stop", "-p", port, err: [:child, :out]]) do |io|
        stringio = StringIO.new
        if verbose?
          IO.copy_stream(io,$stderr)
        else
          IO.copy_stream(io, stringio)
        end
        _, exit_status = Process.wait2(io.pid)

        if exit_status != 0
          stringio.rewind
          raise "Unable to start solr: #{stringio.read}"
        end

        # Wait for solr to stop
        while status
          sleep 1
        end
      end if managed?
    end

    def status
      return true unless managed?

      stringio = StringIO.new

      IO.popen([solr_binary, "status", "-p", port, err: [:child, :out]]) do |io|
        IO.copy_stream(io, stringio)

        _, exit_status = Process.wait2(io.pid)

        stringio.rewind

        if exit_status != 0
          raise "Unable to query solr status: #{stringio.read}"
        end
      end

      out = stringio.read
      out =~ /running on port #{port}/
    end

    def started?
      !!status
    end

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
      unless File.exists? download_path and md5sum(download_path) == expected_md5sum
        pbar = ProgressBar.create(title: File.basename(url), total: nil, format: "%t: |%B| %p%% (%e )")
        open(url, content_length_proc: lambda {|t|
          if t && 0 < t
            pbar.total = t
          end
          },
          progress_proc: lambda {|s|
            pbar.progress = s
          }) do |io|
          IO.copy_stream(io,download_path)
        end

        unless md5sum(download_path) == expected_md5sum
          raise "MD5 mismatch" unless options[:ignore_md5sum]
        end
      end

      download_path
    end

    def port
      options.fetch(:port, "8983")
    end

    def create options = {}
      options[:name] ||= SecureRandom.hex

      IO.popen([solr_binary, "create", "-c", options[:name], "-d", options[:dir], "-p", port, err: [:child, :out]]) do |io|
        if verbose?
          IO.copy_stream(io,$stderr)
        end
      end

      options[:name]
    end
    
    def delete name, options = {}
      IO.popen([solr_binary, "delete", "-c", name, "-p", port, err: [:child, :out]]) do |io|
        if verbose?
          IO.copy_stream(io,$stderr)
        end
      end
    end

    def with_collection options = {}
      name = create(options)
      begin
        yield name
      ensure
        delete name
      end
    end

    private
    def expected_md5sum
      @md5sum ||= options.fetch(:md5sum, open(md5file).read.split(" ").first)
    end

    def md5sum file
      Digest::MD5.file(file).hexdigest
    end

    def md5file
      unless File.exists? md5sum_path
        pbar = ProgressBar.create(title: File.basename(md5url), total: nil, format: "%t: |%B| %p%% (%e )")
        open(md5url, content_length_proc: lambda {|t|
          if t && 0 < t
            pbar.total = t
          end
        },
        progress_proc: lambda {|s|
          pbar.progress = s
        }) do |io|
          IO.copy_stream(io, md5sum_path)
        end
      end

      md5sum_path
    end

    def md5url
      "http://www.us.apache.org/dist/lucene/solr/#{version}/solr-#{version}.zip.md5"
    end

    def md5sum_path
      File.join(Dir.tmpdir, File.basename(md5url))
    end

    def url
      @download_url ||= options.fetch(:url, default_url)
    end

    def default_url
      "http://mirrors.ibiblio.org/apache/lucene/solr/#{version}/solr-#{version}.zip"
    end

    def version
      @version ||= options.fetch(:version, SolrWrapper.default_solr_version)
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

    def tmp_save_dir
      @tmp_save_dir ||= Dir.mktmpdir
    end

    def solr_binary
      File.join(solr_dir, "bin", "solr")
    end
    
    def started! status = true
      @started = status
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