require 'spec_helper'

RSpec.describe SolrWrapper::Client do
  subject { described_class.new('http://localhost:8983/solr/') }

  describe '#exists?' do
    around do |example|
      WebMock.disable_net_connect!
      example.call
      WebMock.allow_net_connect!
    end

    context 'for a solrcloud collection' do
      before do
        stub_request(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json')
          .to_return(status: 200, body: '{ "collections": ["x", "y", "z"]}')
        stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a')
          .to_return(status: 200, body: '{ "status": { "a": {} } }')
      end

      it 'checks if it exists' do
        expect(subject.exists?('x')).to eq true
        expect(subject.exists?('a')).to eq false
      end
    end

    context 'for a solr core' do
      before do
        stub_request(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json')
          .to_return(status: 200, body: '{ "error": { "msg": "Solr instance is not running in SolrCloud mode."} }')
        stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=x')
          .to_return(status: 200, body: '{ "status": { "x": { "name": "x" } } }')
        stub_request(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a')
          .to_return(status: 200, body: '{ "status": { "a": {} } }')
      end

      it 'checks if it exists' do
        expect(subject.exists?('x')).to eq true
        expect(subject.exists?('a')).to eq false
      end
    end
  end
end
