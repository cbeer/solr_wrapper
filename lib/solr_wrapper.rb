require 'solr_wrapper/version'
require 'solr_wrapper/instance'

module SolrWrapper
  def self.default_solr_version
    "5.0.0"
  end

  def self.default_instance
    @default_instance ||= SolrWrapper::Instance.new
  end

  def self.wrap &block
    default_instance.wrap &block
  end
end