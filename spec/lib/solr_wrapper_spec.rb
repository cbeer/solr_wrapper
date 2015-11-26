require 'spec_helper'

describe SolrWrapper do
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

  describe '.default_instance' do
    let(:custom_options) {
      {
          verbose: true,
          cloud: true,
          port: '8983',
          version: '5.3.1',
          instance_dir: 'solr',
          extra_lib_dir: File.join('myconfigs','lib'),
      }
    }
    subject { SolrWrapper.default_instance }
    context 'when @default_instance is not set' do
      before do
        SolrWrapper.remove_instance_variable(:@default_instance)
      end
      it "uses default_instance_options" do
        SolrWrapper.default_instance_options = custom_options
        expect(subject.options).to eq custom_options
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
