require 'solr_wrapper/version'
require 'solr_wrapper/instance'

module SolrWrapper
  def self.default_solr_version
    "5.0.0"
  end

  def self.default_instance options
    @default_instance ||= SolrWrapper::Instance.new options
  end

  def self.wrap options = {}, &block
    default_instance(options).wrap &block
  end
end