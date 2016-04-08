require 'spec_helper'

describe SolrWrapper::Instance do
  let(:solr_instance) { SolrWrapper::Instance.new }
  subject { solr_instance }
  let(:client) { SimpleSolrClient::Client.new(subject.url) }

  describe "#with_collection" do
    context "without a name" do
      it "creates a new anonymous collection" do
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
    context "with a config file" do
      before do
        allow(solr_instance.config).to receive(:collection_options)
          .and_return(name: 'project-development', dir: 'solr/config/')
        allow(solr_instance).to receive(:delete)
      end

      it "creates a new collection with options from the config" do
        expect(solr_instance).to receive(:create).with(
          hash_including(name: "project-development", dir: anything))
        solr_instance.with_collection(dir: File.join(FIXTURES_DIR, "basic_configs")) {}
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

  describe "#host" do
    subject { solr_instance.host }
    it { is_expected.to eq '127.0.0.1' }
  end

  describe "#port" do
    subject { solr_instance.port }
    it { is_expected.to eq '8983' }
  end

  describe "#url" do
    subject { solr_instance.url }
    it { is_expected.to eq 'http://127.0.0.1:8983/solr/' }
  end

  describe "#version" do
    subject { solr_instance.version }
    it { is_expected.to eq '6.0.0' }
  end

  describe "#md5" do
    subject { solr_instance.md5 }
    it { is_expected.to be_instance_of SolrWrapper::MD5 }
  end
end
