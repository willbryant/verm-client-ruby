require 'net/http'

module Verm
  class Client
    attr_reader :http_client

    def initialize(hostname, port: 3404, timeout: 15)
      @http_client = Net::HTTP.new(hostname, port)
      @http_client.open_timeout = timeout
      @http_client.read_timeout = timeout
      @http_client.ssl_timeout = timeout
    end

    def store(directory, io_or_data, content_type, encoding: nil)
      if %w(application/gzip application/x-gzip).include?(content_type) && encoding.nil?
        raise ArgumentError, "Pass the real content-type and encoding: 'gzip' for gzipped uploads" # see 'File compression' in README.md
      end

      directory = "/#{directory}" unless directory[0] == '/'
      request = Net::HTTP::Post.new(directory, 'Content-Type' => content_type)
      request['Content-Encoding'] = encoding.to_s if encoding

      if io_or_data.respond_to?(:read)
        request.body_stream = io_or_data
        if io_or_data.respond_to?(:size)
          request['Content-Length'] = io_or_data.size
        else
          request['Transfer-Encoding'] = 'chunked'
        end

        io_or_data.rewind if io_or_data.respond_to?(:rewind)
        response = http_client.request(request)
      else
        response = http_client.request(request, io_or_data)
      end

      response.error! unless response.is_a?(Net::HTTPSuccess)
      raise "Got a HTTP #{response.code} when trying to store content - should always be 201" unless response.code.to_i == 201
      raise "No location was returned when trying to store content - should always be given" unless response['location']
      response['location']
    end

    def load(path, initheader = {}, force_text_encoding: "UTF-8")
      response = http_client.request_get(path, initheader)
      response.error! unless response.is_a?(Net::HTTPSuccess)

      if force_text_encoding && response.content_type =~ /text\//
        [response.body.force_encoding(force_text_encoding), response.content_type]
      else
        [response.body, response.content_type]
      end
    end

    def stream(path, initheader = {})
      http_client.request_get(path, initheader) do |response|
        response.error! unless response.is_a?(Net::HTTPSuccess)
        response.read_body do |chunk|
          yield chunk
        end
      end
    end
  end
end
