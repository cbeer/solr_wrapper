module SolrWrapper
  class Railtie < Rails::Railtie
    rake_tasks do
      require 'solr_wrapper/rake_task'
    end
  end
end
