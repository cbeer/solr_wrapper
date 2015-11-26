require 'solr_wrapper/version'
require 'solr_wrapper/instance'
require 'solr_wrapper/command_line_wrapper'

module SolrWrapper
  class CollectionNotFoundError < RuntimeError ; end
  class ZookeeperNotRunning < RuntimeError ; end
  def self.default_solr_version
    '5.3.1'
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
    @default_instance ||= SolrWrapper::Instance.new default_instance_options.merge(options)
  end

  # Source directory to copy configurations from
  def self.source_config_dir
    @source_config_dir ||= 'solr'
  end

  def self.source_config_dir=(source_config_dir)
    @source_config_dir = source_config_dir
  end

  ##
  # Ensures a Solr service is running before executing the block
  def self.wrap(options = {}, &block)
    default_instance(options).wrap &block
  end
end
