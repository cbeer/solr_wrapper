require 'ruby-progressbar'
require 'faraday'
require 'faraday/follow_redirects'

module SolrWrapper
  class Downloader
    def self.fetch_with_progressbar(url, output)
      pbar = SafeProgressBar.new(title: File.basename(url), total: nil, format: '%t: |%B| %p%% (%e )')

      client = Faraday.new(url) do |faraday|
        faraday.use Faraday::FollowRedirects::Middleware
        faraday.adapter Faraday.default_adapter
      end

      File.open(output, 'wb') do |f|
        client.get do |req|
          req.options.on_data = Proc.new do |chunk, overall_received_bytes, env|
            if env
              pbar.total = env.response_headers['content-length'].to_i
              pbar.progress = overall_received_bytes
            else
              pbar.increment
            end

            pbar.progress = overall_received_bytes
            f.write(chunk)
          end
        end
      end

      true
    rescue Faraday::Error => e
      raise SolrWrapperError, "Unable to download solr from #{url}\n#{e}"
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
