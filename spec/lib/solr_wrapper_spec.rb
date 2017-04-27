require 'spec_helper'

describe SolrWrapper do
  before do
    FakeWeb.register_uri(:get, 'http://lucene.apache.org/solr/', body: 'the 4.4.4 version is 6.5.1 as of today')
  end
  
  describe ".wrap" do
    it "should launch solr" do
      SolrWrapper.wrap do |solr|
        expect do
          Timeout::timeout(15) do
            TCPSocket.new('127.0.0.1', solr.port).close
          end
        end.not_to raise_exception
      end
    end
  end

  describe '.instance' do
    context 'without arguments' do
      it 'inherits the defaults' do
        expect(SolrWrapper.instance.port).to eq '8983'
      end
    end
  end

  describe ".default_instance_options=" do
    it "sets default options" do
      SolrWrapper.default_instance_options = { port: '1234' }
      expect(SolrWrapper.default_instance_options[:port]). to eq '1234'
    end
  end
end
