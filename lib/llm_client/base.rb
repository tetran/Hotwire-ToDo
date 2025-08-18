module LlmClient
  class Base
    def initialize(api_key:, **options)
      @api_key = api_key
      @options = options
    end

    def models
      raise NotImplementedError, "Subclasses must implement #models"
    end

    def chat(messages:, model:, **options)
      raise NotImplementedError, "Subclasses must implement #chat"
    end

    private

      attr_reader :api_key, :options

      def http_request(method, url, headers: {}, body: nil)
        response = exec_http_request(method, url, headers, body)

        case response.code.to_i
        when 200..299
          JSON.parse(response.body)
        else
          raise ApiError.new("HTTP #{response.code}: #{response.body}", response.code.to_i)
        end
      rescue JSON::ParserError => e
        raise ApiError, "Invalid JSON response: #{e.message}"
      rescue StandardError => e
        raise ApiError, "Request failed: #{e.message}"
      end

      def exec_http_request(method, url, headers, body)
        uri = URI(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = case method
                  when :get
                    Net::HTTP::Get.new(uri)
                  when :post
                    Net::HTTP::Post.new(uri)
                  else
                    raise ArgumentError, "Unsupported HTTP method: #{method}"
                  end

        headers.each { |key, value| request[key] = value }
        request.body = body if body
        http.request(request)
      end
  end

  class ApiError < StandardError
    attr_reader :status_code

    def initialize(message, status_code = nil)
      super(message)
      @status_code = status_code
    end
  end
end
