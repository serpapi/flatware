require 'cucumber'
require 'flatware/cucumber/formatter'
require 'flatware/cucumber/result'
require 'flatware/cucumber/step_result'
require 'flatware/cucumber/formatters/console'
require 'flatware/cucumber/cli'

module Flatware
  module Cucumber
    class Config
      attr_reader :config, :args

      def initialize(cucumber_config, args)
        @config = cucumber_config
        @args = args
      end

      def feature_dir
        @config.feature_dirs.first
      end

      def jobs
        feature_files.map { |file| Job.new file, args }.to_a
      end

      private

      def feature_files
        config.feature_files - config.feature_dirs
      end
    end

    module_function

    def configure(args, out_stream = $stdout, error_stream = $stderr)
      raw_args = args.dup
      cli_config = ::Cucumber::Cli::Configuration.new(out_stream, error_stream)
      cli_config.parse! args + %w[--format Flatware::Cucumber::Formatter --publish-quiet]
      cucumber_config = ::Cucumber::Configuration.new cli_config
      Config.new cucumber_config, raw_args
    end

    def run(feature_files, options)
      config = configure(Array(feature_files) + options).config
      forget_loaded_support_code(config)
      ::Cucumber::Runtime.new(config).run!
    end

    # Each job builds a new Runtime with an empty step registry, but Cucumber loads support code
    # with `require`, which is a no-op for files a previous job in this process already loaded.
    def forget_loaded_support_code(config)
      files = config.all_files_to_load.map { |file| File.expand_path(file) }
      $LOADED_FEATURES.reject! { |feature| files.include?(feature) }
    end
  end
end
