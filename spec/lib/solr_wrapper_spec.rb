require 'spec_helper'

describe SolrWrapper do
  describe ".wrap" do
    it "should launch solr" do
      SolrWrapper.wrap do |solr|
        expect(Timeout::timeout(15) do
          begin
            s = TCPSocket.new('127.0.0.1', solr.port)
            s.close
            true
          rescue
            false
          end
        end).to eq true
      end
    end
  end
end