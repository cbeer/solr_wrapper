require 'spec_helper'

RSpec.describe SolrWrapper::ChecksumValidator do
  let(:validator) { described_class.new(settings) }
  let(:settings) { SolrWrapper::Settings.new(config) }
  let(:config) { SolrWrapper::Configuration.new(options) }
  let(:options) { { version: '6.6.0'} }

  describe '#checksumurl' do
    subject { validator.send(:checksumurl, described_class::ALGORITHM) }

    it { is_expected.to eq 'http://archive.apache.org/dist/lucene/solr/6.6.0/solr-6.6.0.zip.sha1' }
  end
end
