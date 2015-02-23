require 'spec_helper'

describe SolrWrapper do
  describe ".wrap" do
    it "should launch solr" do
      SolrWrapper.wrap do |solr|
        expect {
          Timeout::timeout(15) do
            TCPSocket.new('127.0.0.1', solr.port).close
          end
        }.not_to raise_exception
      end
    end
  end
end