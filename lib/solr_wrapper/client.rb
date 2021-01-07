require 'http'
require 'json'

module SolrWrapper
  # Solr REST API client to get status information
  class Client
    attr_reader :url

    def initialize(url)
      @url = url
    end

    # Check if a core or collection exists
    def exists?(core_or_collection_name)
      collection?(core_or_collection_name) || core?(core_or_collection_name)
    end

    private

    def collection?(name)
      response = HTTP.get("#{url}admin/collections?action=LIST&wt=json")
      data = JSON.parse(response.body)
      return if data['error'] && data['error']['msg'] == 'Solr instance is not running in SolrCloud mode.'

      data['collections'].include? name
    end

    def core?(name)
      response = HTTP.get("#{url}admin/cores?action=STATUS&wt=json&core=#{name}")
      !JSON.parse(response.body)['status'][name].empty?
    end
  end
end
