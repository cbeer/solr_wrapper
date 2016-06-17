require 'spec_helper'

describe SolrWrapper::Client do
  subject { described_class.new('http://localhost:8983/solr/') }

  describe '#exists?' do
    it 'checks if a solrcloud collection exists' do
      FakeWeb.register_uri(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json', body: '{ "collections": ["x", "y", "z"]}')
      FakeWeb.register_uri(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a', body: '{ "status": { "a": {} } }')

      expect(subject.exists?('x')).to eq true
      expect(subject.exists?('a')).to eq false
    end

    it 'checks if a solr core exists' do
      FakeWeb.register_uri(:get, 'http://localhost:8983/solr/admin/collections?action=LIST&wt=json', body: '{ "error": { "msg": "Solr instance is not running in SolrCloud mode."} }')

      FakeWeb.register_uri(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=x', body: '{ "status": { "x": { "name": "x" } } }')
      FakeWeb.register_uri(:get, 'http://localhost:8983/solr/admin/cores?action=STATUS&wt=json&core=a', body: '{ "status": { "a": {} } }')

      expect(subject.exists?('x')).to eq true
      expect(subject.exists?('a')).to eq false
    end
  end
end
