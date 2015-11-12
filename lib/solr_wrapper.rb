require 'solr_wrapper/version'
require 'solr_wrapper/instance'

module SolrWrapper
  def self.default_solr_version
    '5.3.1'
  end

  def self.default_instance(options = {})
    @default_instance ||= SolrWrapper::Instance.new options
  end

  ##
  # Ensures a Solr service is running before executing the block
  def self.wrap(options = {}, &block)
    default_instance(options).wrap &block
  end

  ##
  # Extract a copy of solr if it is not already there
  # @see SolrWrapper::Instance.extract
  def self.extract(options = {})
    default_instance(options).extract
  end

  ##
  # Extract a copy of solr if it is not already there
  # @see SolrWrapper::Instance.extract
  def self.configure(options = {})
    default_instance(options).configure
  end

  ##
  # Extract a copy of solr if it is not already there
  # @see SolrWrapper::Instance.extract
  def self.extract_and_configure(options = {})
    default_instance(options).extract_and_configure
  end

  ##
  # Remove anything at +solr_dir+ and then extract a clean copy
  # of solr to that location.
  # @see SolrWrapper::Instance.clean
  def self.clean(options = {})
    default_instance(options).clean!
    default_instance(options).extract_and_configure
  end
end
