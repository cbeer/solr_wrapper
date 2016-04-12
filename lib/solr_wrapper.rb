require 'solr_wrapper/version'
require 'solr_wrapper/configuration'
require 'solr_wrapper/settings'
require 'solr_wrapper/md5'
require 'solr_wrapper/downloader'
require 'solr_wrapper/instance'

module SolrWrapper
  def self.default_solr_version
    '6.0.0'
  end

  def self.default_instance_options
    @default_instance_options ||= {
      port: '8983',
      version: SolrWrapper.default_solr_version
    }
  end

  def self.default_instance_options=(options)
    @default_instance_options = options
  end

  def self.default_instance(options = {})
    @default_instance ||= instance(default_instance_options)
  end

  def self.instance(options)
    SolrWrapper::Instance.new(options)
  end

  ##
  # Ensures a Solr service is running before executing the block
  def self.wrap(options = {}, &block)
    instance(options).wrap &block
  end
end
