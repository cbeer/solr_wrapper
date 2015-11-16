require 'spec_helper'

describe SolrWrapper::Instance do
  let(:solr_instance) { SolrWrapper::Instance.new }
  subject { solr_instance }
  let(:client) { SimpleSolrClient::Client.new(subject.url) }
  describe "#with_collection" do
    it "should create a new anonymous collection" do
      subject.wrap do |solr|
        solr.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) do |collection_name|
          core = client.core(collection_name)
          unless defined? JRUBY_VERSION
            expect(core.schema.field('id').name).to eq 'id'
            expect(core.schema.field('id').stored).to eq true
          end
        end
      end
    end
  end
  describe 'exec' do
    let(:cmd) { 'start' }
    let(:options) { { p: '4098', help: true } }
    subject { solr_instance.send(:exec, cmd, options) }
    it 'runs the command' do
      result_io = subject
      expect(result_io.read).to include('Usage: solr start')
    end
    it 'accepts boolean flags' do
      result_io = solr_instance.send(:exec, 'start', p: '4098', help: true)
      expect(result_io.read).to include('Usage: solr start')
    end

    describe 'when something goes wrong' do
      let(:cmd) { 'healthcheck' }
      let(:options) { { z: 'localhost:5098' } }
      it 'raises an error with the output from the shell command' do
        expect { subject }.to raise_error(RuntimeError, /Failed to execute solr healthcheck: collection parameter is required!/)
      end
    end
  end
end
