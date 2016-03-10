module SolrWrapper
  class Downloader
    def self.fetch_with_progressbar(url, output)
      pbar = ProgressBar.create(title: File.basename(url), total: nil, format: "%t: |%B| %p%% (%e )")
      open(url, content_length_proc: lambda do|t|
        if t && 0 < t
          pbar.total = t
        end
      end,
                progress_proc: lambda do|s|
                  pbar.progress = s
                end) do |io|
        IO.copy_stream(io, output)
      end
    end
  end
end
