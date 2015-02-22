require 'digest'
require 'fileutils'
require 'open-uri'
require 'progressbar'
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
        if verbose?
          IO.copy_stream(io,$stderr)
        end
      end if managed?
      started!
    end

    def stop
      return unless started?

      IO.popen([solr_binary, "stop", "-p", port, err: [:child, :out]]) do |io|
        if verbose?
          IO.copy_stream(io,$stderr)
        end
      end if managed?
    end

    def started?
      !!@started
    end

    def started! status = true
      @started = status
    end

    def extract
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
        FileUtils.chmod 0755, solr_binary
      rescue Exception => e
        abort "Unable to copy #{tmp_save_dir} to #{solr_dir}: #{e.message}"
      end

      solr_dir
    ensure
      FileUtils.remove_entry tmp_save_dir
    end

    def download
      unless File.exists? download_path and md5sum(download_path) == expected_md5sum
        pbar = ProgressBar.new("solr", nil)
        open(url, content_length_proc: lambda {|t|
          if t && 0 < t
            pbar.total = t
            pbar.file_transfer_mode
          end
          },
          progress_proc: lambda {|s|
            pbar.set s if pbar
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

    private
    def expected_md5sum
      @md5sum ||= options.fetch(:md5sum, open(md5file).read.split(" ").first)
    end

    def md5sum file
      Digest::MD5.file(file).hexdigest
    end

    def md5file
      unless File.exists? md5sum_path
        pbar = ProgressBar.new("md5", nil)
        open(md5url, content_length_proc: lambda {|t|
          if t && 0 < t
            pbar.total = t
            pbar.file_transfer_mode
          end
        },
        progress_proc: lambda {|s|
          pbar.set s if pbar
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

    def verbose?
      !!options[:verbose]
    end
  end
end