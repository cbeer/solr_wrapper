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
          instance_dir: 'solr'
      }
    end
    @solr_instance = SolrWrapper.default_instance(SOLR_OPTIONS)
  end

  desc 'Install a clean version of solr. Replaces the existing copy if there is one.'
  task :clean => :environment do
    puts "Installing clean version of solr at #{File.expand_path(@solr_instance.solr_dir)}"
    @solr_instance.clean!
    @solr_instance.extract_and_configure
  end

  desc 'start solr'
  task :start => :environment do
    begin
      puts "Starting solr at #{File.expand_path(@solr_instance.solr_dir)} with options #{@solr_instance.options}"
      @solr_instance.start
    rescue
      puts '... something went wrong. Stopping solr.'
      @solr_instance.stop
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
