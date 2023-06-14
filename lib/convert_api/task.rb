module ConvertApi
  class Task
    def initialize(from_format, to_format, params, conversion_timeout: nil)
      @from_format = from_format
      @to_format = to_format
      @conversion_timeout = conversion_timeout || config.conversion_timeout
      @params = {
        Timeout: @conversion_timeout,
        StoreFile: true,
      }.merge(normalize_params(params)
    end

    def run
      read_timeout = @conversion_timeout + config.conversion_timeout_delta if @conversion_timeout

      response = ConvertApi.client.post(
        request_path,
        @params,
        read_timeout: read_timeout,
      )

      return AsyncResult.new(response) if async?

      Result.new(response)
    end

    private

    def async?
      @async ||= !!@params[:Async]
    end

    def request_path
      from_format = @from_format || detect_format
      converter = @params[:converter] ? "/converter/#{@params[:converter]}" : ''
      async = async? ? 'async/' : ''

      "#{async}convert/#{from_format}/to/#{@to_format}#{converter}"
    end

    def normalize_params(params)
      result = {}

      symbolize_keys(params).each do |key, value|
        case key
        when :File
          result[:File] = FileParam.build(value)
        when :Files
          result[:Files] = files_batch(value)
        else
          result[key] = value
        end
      end

      result
    end

    def symbolize_keys(hash)
      hash.map { |k, v| [k.to_sym, v] }.to_h
    end

    def files_batch(values)
      files = Array(values).map { |file| FileParam.build(file) }

      # upload files in parallel
      files
        .select { |file| file.is_a?(UploadIO) }
        .map { |upload_io| Thread.new { upload_io.file_id } }
        .map(&:join)

      files
    end

    def detect_format
      return DEFAULT_URL_FORMAT if @params[:Url]

      resource = @params[:File] || Array(@params[:Files]).first

      FormatDetector.new(resource, @to_format).run
    end

    def config
      ConvertApi.config
    end
  end
end
