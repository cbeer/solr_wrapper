require 'solr_wrapper'

## These tasks get loaded into the host context when solr_wrapper is required
namespace :solr do

  desc "Load the solr options and solr instance"
  task :environment do
    unless defined? SOLR_OPTIONS
      SOLR_OPTIONS = {
          verbose: true,
          cloud: true,
          port: '8983',
          version: '5.3.1',
          instance_dir: 'solr',
          validate_existing: false
      }
    end
    SOLR_OPTIONS[:validate_existing] ||= false
    SOLR_OPTIONS[:download_dir] ||= Rails.root.to_s + '/tmp' if defined? Rails
    @solr_instance = SolrWrapper.default_instance(SOLR_OPTIONS)
  end

  desc 'Install a clean version of solr. Replaces the existing copy if there is one.'
  task :clean => :environment do
    puts "Installing clean version of solr at #{File.expand_path(@solr_instance.solr_dir)}"
    @solr_instance.clean!(keep_zip: true)
    @solr_instance.extract_and_configure
  end

  desc 'start solr'
  task :start => :environment do
    begin
      puts "Starting solr at #{File.expand_path(@solr_instance.solr_dir)} with options #{@solr_instance.options}"
      @solr_instance.start
    rescue => e
      if e.message.include?("Port #{@solr_instance.port} is already being used by another process")
        puts "FAILED. Port #{@solr_instance.port} is already being used."
        puts " Did you already have solr running?"
        puts "  a) YES: Continue as you were. Solr is running."
        puts "  b) NO: Either set SOLR_OPTIONS[:port] to a different value or stop the process that's using port #{@solr_instance.port}."
      else
        raise RuntimeError, "Failed to start solr. #{e.class}: #{e.message}"
      end
    end
  end

  desc 'restart solr'
  task :restart => :environment do
    puts "Restarting solr"
    @solr_instance.restart
  end

  desc 'stop solr'
  task :stop => :environment do
    @solr_instance.stop
  end

end
