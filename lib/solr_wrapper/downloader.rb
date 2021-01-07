require 'ruby-progressbar'

module SolrWrapper
  class Downloader
    def self.fetch_with_progressbar(url, output)
      pbar = SafeProgressBar.new(title: File.basename(url), total: nil, format: '%t: |%B| %p%% (%e )')
      client = Faraday.new(url)

      headers = client.head.headers
      pbar.total = headers['content-length'].to_i

      File.open(output, 'w') do |f|
        client.get do |req|
          req.options.on_data = proc do |chunk, size|
            pbar.progress = size
            f.write(chunk)
          end
        end
      end
    rescue Faraday::Error => e
      raise SolrWrapperError, "Unable to download solr from #{url}\n#{e.message}: #{e.io.read}"
    end

    class SafeProgressBar < ProgressBar::Base
      def progress=(new_progress)
        self.total = new_progress if total.to_i <= new_progress
        super
      end

      def total=(new_total)
        super if new_total && new_total >= 0
      end
    end
  end
end
