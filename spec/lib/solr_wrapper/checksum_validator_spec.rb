require 'spec_helper'

RSpec.describe SolrWrapper::ChecksumValidator do
  let(:validator) { described_class.new(settings) }
  let(:settings) { SolrWrapper::Settings.new(config) }
  let(:config) { SolrWrapper::Configuration.new(options) }

  describe '#checksumurl' do
    subject { validator.send(:checksumurl, described_class::ALGORITHM) }

    context 'when the checksum option is not set' do
      let(:options) { { version: '6.6.0'} }
      it { is_expected.to eq 'http://archive.apache.org/dist/lucene/solr/6.6.0/solr-6.6.0.zip.sha1' }
    end

    context 'when the checksum option is not a URL' do
      let(:options) { { version: '6.6.1', checksum: './just/a/path.sha1'} }
      it { is_expected.to eq 'http://archive.apache.org/dist/lucene/solr/6.6.1/solr-6.6.1.zip.sha1' }
    end

    context 'when the checksum option is a URL' do
      let(:options) { { version: '6.6.2', checksum: 'http://lib-solr-mirror.princeton.edu/dist/lucene/solr/6.6.2/solr-6.6.2.zip.sha1'} }
      it { is_expected.to eq 'http://lib-solr-mirror.princeton.edu/dist/lucene/solr/6.6.2/solr-6.6.2.zip.sha1' }
    end
  end
end
