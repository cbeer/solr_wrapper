require 'solr_wrapper/version'
require 'solr_wrapper/configuration'
require 'solr_wrapper/settings'
require 'solr_wrapper/md5'
require 'solr_wrapper/downloader'
require 'solr_wrapper/instance'
require 'solr_wrapper/client'
require 'solr_wrapper/solr_version_finder'

module SolrWrapper
  def self.default_solr_version
    SolrVersionFinder.find_recent_version || '6.5.0'
  end

  def self.default_solr_port
    '8983'
  end

  def self.default_instance_options
    @default_instance_options ||= {
      port: SolrWrapper.default_solr_port,
      version: SolrWrapper.default_solr_version
    }
  end

  def self.default_instance_options=(options)
    @default_instance_options = options
  end

  def self.default_instance(options = {})
    @default_instance ||= instance(default_instance_options)
  end

  def self.instance(options = {})
    SolrWrapper::Instance.new(options)
  end

  ##
  # Ensures a Solr service is running before executing the block
  def self.wrap(options = {}, &block)
    instance(options).wrap &block
  end

  class SolrWrapperError < StandardError; end
end
