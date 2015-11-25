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
  describe 'configure' do
    subject { solr_instance.configure }
    context 'when extra_lib_dir is specified' do
      before { solr_instance.options[:extra_lib_dir] = 'foo/bar' }
      it 'copies the contents of extra_lib_dir into the solr/lib directory' do
        expect(File).to receive(:exist?).with('foo/bar').and_return(true)
        expect(FileUtils).to receive(:cp_r).with('foo/bar/.', "#{solr_instance.instance_dir}/server/solr/lib")
        subject
      end
      it 'does not try to copy anything if extra_lib_dir does not exist' do
        expect(File).to receive(:exist?).with('foo/bar').and_return(false)
        expect(FileUtils).to_not receive(:cp_r)
        allow(solr_instance).to receive(:puts)
        subject
      end
    end
    context 'when extra_lib_dir is not specified' do
      it 'does not try to copy anything' do
        expect(File).to_not receive(:exist?)
        expect(FileUtils).to_not receive(:cp_r)
        subject
      end
    end
  end
  describe 'destroy' do
    subject { solr_instance.destroy }
    it 'stops solr and deletes the entire instance_dir' do
      expect(solr_instance).to receive(:stop)
      expect(FileUtils).to receive(:rm_rf).with(solr_instance.instance_dir)
      subject
    end
  end
  describe 'cloud commands' do
    let(:collection_name) { 'test_collection' }
    let(:existing_collection) { solr_instance.create(collection_name) }
    let(:collection_config_dir) { File.join(FIXTURES_DIR, "basic_configs") }
    let(:solr_instance) { @solr_instance }
    before(:all) do
      @solr_instance = SolrWrapper::Instance.new(cloud: true)
      @solr_instance.start
    end
    after(:all) do
      @solr_instance.stop
    end
    describe 'create' do
      subject { solr_instance.create(collection_name, dir:collection_config_dir) }
      after { solr_instance.delete(collection_name) }
      it 'creates a collection' do
        expect(solr_instance.collection_exists?(collection_name)).to eq false
        expect(subject).to eq collection_name
        expect(solr_instance.collection_exists?(collection_name)).to eq true
      end
    end
    describe 'delete' do
      subject { solr_instance.delete(existing_collection) }
      it 'deletes a collection' do
        expect(solr_instance.collection_exists?(existing_collection)).to eq true
        subject
        expect(solr_instance.collection_exists?(existing_collection)).to eq false
      end
    end
    describe 'create_or_update' do
      subject { solr_instance.create_or_update(collection_name, dir:collection_config_dir) }
      context 'when the collection does not exist' do
        before do
          expect(solr_instance).to receive(:collection_exists?).and_return(false)
        end
        it 'creates the collection' do
          expect(solr_instance).to_not receive(:delete)
          expect(solr_instance).to receive(:create).with(collection_name, dir:collection_config_dir)
          subject
        end
      end
      context 'when the collection already exists' do
        before do
          expect(solr_instance).to receive(:collection_exists?).and_return(true)
        end
        it 'delete the collection and then creates it again' do
          expect(solr_instance).to receive(:delete).with(collection_name, dir:collection_config_dir)
          expect(solr_instance).to receive(:create).with(collection_name, dir:collection_config_dir)
          subject
        end
      end
    end
    describe 'healthcheck' do
      context 'when the collection does not exist' do
        subject { solr_instance.healthcheck('nonexistent') }
        it 'raises an error' do
          expect { subject }.to raise_error(SolrWrapper::CollectionNotFoundError)
        end
      end
      context 'when the collection exists' do
        subject { solr_instance.healthcheck(existing_collection) }
        after { solr_instance.delete(existing_collection) }
        it 'returns info about the collection' do
          expect(subject).to be_instance_of StringIO
          json = JSON.parse(subject.read)
          expect(json['collection']).to eq existing_collection
          expect(json['status']).to eq 'healthy'
          expect(json['numDocs']).to eq 0
        end
      end
      context 'when zookeeper is not running' do
        let(:wrapper_error_message) { "Zookeeper is not running at #{solr_instance.host}:#{solr_instance.zkport}. Are you sure solr is running in cloud mode?" }
        it 'raises an appropriate error' do
          expect(solr_instance).to receive(:exec).and_raise(RuntimeError, "ERROR: java.lang.IllegalArgumentException: port out of range:65831")
          expect{ solr_instance.healthcheck('foo') }.to raise_error(SolrWrapper::ZookeeperNotRunning, wrapper_error_message)
          expect(solr_instance).to receive(:exec).and_raise(RuntimeError, "org.apache.zookeeper.ClientCnxn$SendThread; Session 0x0 for server null, unexpected error, closing socket connection and attempting reconnect")
          expect{ solr_instance.healthcheck('foo') }.to raise_error(SolrWrapper::ZookeeperNotRunning, wrapper_error_message)
          expect(solr_instance).to receive(:exec).and_raise(RuntimeError, "ERROR: java.util.concurrent.TimeoutException: Could not connect to ZooKeeper 127.0.0.1:58499 within 10000 ms")
          expect{ solr_instance.healthcheck('foo') }.to raise_error(SolrWrapper::ZookeeperNotRunning, wrapper_error_message)
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
