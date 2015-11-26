module SolrWrapper
  class CommandLineWrapper

    ##
    # Run a bin/solr command
    # @param [String] cmd command to run.  Most commands will map to solr binary.  :zookeeper will call zkcli.sh
    # @param [Hash] options key-value pairs to transform into command line arguments
    # @return [StringIO] an IO object for the executed shell command
    # @see https://github.com/apache/lucene-solr/blob/trunk/solr/bin/solr
    # If you want to pass a boolean flag, include it in the +options+ hash with its value set to +true+
    # the key will be converted into a boolean flag for you.
    # @example start solr in cloud mode on port 8983
    #   exec('start', {p: '8983', c: true})
    def self.exec(executable ,cmd=nil, options = {}, env={})
      silence_output = !options.delete(:output)
      args = command_line_args(executable, cmd, options)
      if IO.respond_to? :popen4
        # JRuby
        env_str = env.map { |k, v| "#{Shellwords.escape(k)}=#{Shellwords.escape(v)}" }.join(" ")
        pid, input, output, error = IO.popen4(env_str + " " + args.join(" "))
        @pid = pid
        stringio = StringIO.new
        if options.fetch(:verbose, false) && !silence_output
          IO.copy_stream(output, $stderr)
          IO.copy_stream(error, $stderr)
        else
          IO.copy_stream(output, stringio)
          IO.copy_stream(error, stringio)
        end

        input.close
        output.close
        error.close
        exit_status = Process.waitpid2(@pid).last
      else
        IO.popen(env, args + [err: [:child, :out]]) do |io|
          stringio = StringIO.new

          if options.fetch(:verbose, false) && !silence_output
            IO.copy_stream(io, $stderr)
          else
            IO.copy_stream(io, stringio)
          end

          @pid = io.pid

          _, exit_status = Process.wait2(io.pid)
        end
      end

      stringio.rewind
      if exit_status != 0
        raise "Failed to execute solr #{cmd}: #{stringio.read}"
      end

      stringio
    end

    # Build the array of arguments to pass to command line
    def self.command_line_args(executable, cmd, options={})
    args = [executable]
    args << cmd unless cmd.nil?
    args += options.map do |k, v|
      case v
        when true
          "-#{k}"
        when false, nil
          # don't return anything
        else
          ["-#{k}", "#{v}"]
      end
    end.flatten.compact
    end
  end

end
