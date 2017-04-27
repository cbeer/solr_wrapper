require 'open-uri'
module SolrWrapper
  module SolrVersionFinder
    # Screenscrape the apache site and make a guess about what the current version is.
    def self.find_recent_version
      version = open('http://lucene.apache.org/solr/').read.scan(/\d+\.\d+\.\d+/).last
      $stderr.puts "Solr version couldn't be retrieved" unless version
      version
    end
  end
end
