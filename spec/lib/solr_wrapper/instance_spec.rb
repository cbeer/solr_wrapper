require 'spec_helper'

describe SolrWrapper::Instance do
  # WebMock messes with HTTP.rbs ability to stream responses
  before(:all) do
    WebMock.disable!
  end

  after(:all) do
    WebMock.enable!
  end

  let(:options) { {} }
  let(:solr_instance) { SolrWrapper::Instance.new(options) }
  subject { solr_instance }
  let(:client) do
    SolrWrapper::Client.new(subject.url)
  end

  let(:config_dir) do
    version = solr_instance.config.version

    version.start_with?(/1\d/) ? File.join(FIXTURES_DIR, 'basic_configs_v10') : File.join(FIXTURES_DIR, 'basic_configs_v9')
  end

  describe "#with_collection" do
    let(:options) { { cloud: false } }
    context "without a name" do
      it "creates a new anonymous collection" do
        subject.wrap do |solr|
          solr.with_collection(dir: config_dir) do |collection_name|
            expect(client.exists?(collection_name)).to be true
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
        solr_instance.with_collection(dir: config_dir) {}
      end
    end

    context 'persistent collections' do
      it "creates a new collection with options from the config" do
        expect(solr_instance).to receive(:create).with(
          hash_including(name: 'project-development'))
        expect(solr_instance).not_to receive(:delete)
        solr_instance.with_collection(name: 'project-development', dir: 'solr/config/', persist: true) {}
      end

      describe 'single solr node' do
        it 'allows persistent collection on restart' do
          subject.wrap do |solr|
            solr.with_collection(name: 'solr-node-persistent-core', dir: config_dir, persist: true) {}
          end

          subject.wrap do |solr|
            solr.with_collection(name: 'solr-node-persistent-core', dir: config_dir, persist: true) {}
            solr.delete 'solr-node-persistent-core'
          end
        end
      end

      describe 'solr cloud' do
        let(:options) { { cloud: true } }

        it 'allows persistent collection on restart' do
          subject.wrap do |solr|
            config_name = solr.upconfig dir: config_dir
            solr.with_collection(name: 'solr-cloud-persistent-collection', config_name: config_name, persist: true) {}
          end

          subject.wrap do |solr|
            solr.with_collection(name: 'solr-cloud-persistent-collection', persist: true) {}
            solr.delete 'solr-cloud-persistent-collection'
          end
        end
      end
    end
  end

  context 'with a SolrCloud instance' do
    let(:options) { { cloud: true } }
    it 'can upload configurations' do
      subject.wrap do |solr|
        config_name = solr.upconfig dir: config_dir
        Dir.mktmpdir do |dir|
          solr.downconfig name: config_name, dir: dir
        end
        solr.with_collection(config_name: config_name) do |collection_name|
          client.exists? collection_name
        end
      end
    end

    context 'with a config file' do
      before do
        allow(solr_instance.config).to receive(:configsets)
          .and_return([name: 'project-development', dir: 'solr/config/'])
      end

      it 'creates a new configsets with options from the config' do
        expect(subject).to receive(:upconfig).with(
          hash_including(name: 'project-development', dir: anything))

        subject.wrap do
          # no-op
        end
      end
    end
  end

  describe 'exec' do
    let(:cmd) { 'start' }
    let(:options) { { p: '4098' } }
    subject { solr_instance.send(:exec, cmd, options) }

    describe 'when something goes wrong' do
      let(:cmd) { 'healthcheck' }
      let(:options) { { z: 'localhost:5098' } }
      it 'raises an error with the output from the shell command' do
        expect { subject }.to raise_error(RuntimeError, Regexp.union(/Failed to execute solr healthcheck: collection parameter is required!/, /Failed to parse command-line arguments due to: Missing required option: c/))
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

  describe "#instance_dir" do
    subject { solr_instance.instance_dir }
    it { is_expected.to start_with Dir.tmpdir }
  end

  describe "#version" do
    before do
      allow(solr_instance.config).to receive(:version).and_return('solr-version-number')
    end

    subject { solr_instance.version }
    it { is_expected.to eq 'solr-version-number' }
  end

  describe "#checksum_validator" do
    subject { solr_instance.send(:checksum_validator) }
    it { is_expected.to be_instance_of SolrWrapper::ChecksumValidator }
  end
end
