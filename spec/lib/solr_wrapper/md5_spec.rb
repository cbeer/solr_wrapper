require 'spec_helper'

describe SolrWrapper::MD5 do
  let(:options) { { md5sum: md5sum } }
  let(:solr_instance) { SolrWrapper::Instance.new(options) }
  subject { solr_instance.md5 }

  describe "#expected_sum" do
    context ":md5sum option is an acual sum" do
      let(:md5sum) { "0123456789abcdef0123456789abcdef" }

      it "returns passed in md5sum" do
        expect(subject.send(:expected_sum)).to eq(md5sum)
      end
    end

    context ":md5sum options is a URL to a file containing the md5sum" do
      url = "http://www.foobar.com/solr.zip.md5"
      let(:md5sum) { url }

      it "returns md5sum from URL" do
        md5 = "fedcba9876543210fedcba9876543210"
        File.open("/tmp/www-foobar-com.solr.md5", "w") { |f| f.puts md5 }

        stub_request(:any, url).
          to_return(body: File.new('/tmp/www-foobar-com.solr.md5'), status: 200)

        expect(subject.send(:expected_sum)).to eq(md5)
      end
    end

    context ":md5sum option is not set" do
      let(:options) { {} }

      it "returns md5sum from default md5url" do
        expect(subject.send(:expected_sum)).to match(/^[a-f0-9]{32}$/)
      end
    end
  end
end
