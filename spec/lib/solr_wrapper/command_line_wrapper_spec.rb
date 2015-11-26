describe SolrWrapper::CommandLineWrapper do
  let(:solr_instance) { SolrWrapper::Instance.new }
  let(:executable) { solr_instance.send(:solr_binary) }
  let(:cmd) { 'start' }
  let(:options) { { p: '4098', help: true } }

  describe '.exec' do
    subject { described_class.exec(executable, cmd, options) }
    it 'runs the command' do
      result_io = subject
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

  describe ".command_line_args" do
    subject { described_class.command_line_args(executable, cmd, options) }
    it 'constructs the full set of arguments to pass to the command line' do
      expect(subject.join(' ')).to eq "#{executable} start -p 4098 -help"
    end
    it 'accepts boolean flags' do
      result_io = described_class.exec(executable, 'start', p: '4098', help: true)
      expect(result_io.read).to include('Usage: solr start')
    end
    context 'when requesting zookeeper' do
      let(:executable) { solr_instance.send(:zookeeper_cli) }
      let(:cmd) { nil }
      let(:options) { { cmd: 'bootstrap', foo: 'bar' } }
      it 'calls the zookeeper cli script instead of solr_binary' do
        expect(subject.join(' ')).to eq "#{executable} -cmd bootstrap -foo bar"
      end
    end
  end
end