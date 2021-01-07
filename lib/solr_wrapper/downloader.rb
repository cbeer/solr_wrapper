require 'ruby-progressbar'
require 'http'

module SolrWrapper
  class Downloader
    def self.fetch_with_progressbar(url, output)
      pbar = SafeProgressBar.new(title: File.basename(url), total: nil, format: '%t: |%B| %p%% (%e )')

      response = HTTP.follow.get(url)
      pbar.total = response.headers['content-length'].to_i

      File.open(output, 'w') do |f|
        response.body.each do |chunk|
          f.write(chunk)
          pbar.progress += chunk.length
        end

        nil
      end
    rescue HTTP::Error => e
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
