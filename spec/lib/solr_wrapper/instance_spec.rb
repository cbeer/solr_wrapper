require 'spec_helper'

describe SolrWrapper::Instance do
  subject { SolrWrapper::Instance.new }
  let(:client) { SimpleSolrClient::Client.new("http://localhost:#{subject.port}/solr/") }
  describe "#with_collection" do
    it "should create a new anonymous collection" do
      subject.wrap do |solr|
        solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
          core = client.core(collection_name)
          expect(core.schema.field('id').name).to eq 'id'
          expect(core.schema.field('id').stored).to eq true
        end
      end
    end
  end
end