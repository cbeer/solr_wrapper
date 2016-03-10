require 'spec_helper'

describe SolrWrapper::Configuration do
  let(:config) { described_class.new options }

  describe "#port" do
    subject { config.port }

    context "when port is set to nil" do
      let(:options) { { port: nil } }
      it { is_expected.to eq nil }
    end

    context "when port is not set" do
      let(:options) { {} }
      it { is_expected.to eq '8983' }
    end

    context "when a port is provided" do
      let(:options) { { port: '8888' } }
      it { is_expected.to eq '8888' }
    end
  end
end
