# frozen_string_literal: true

module Birth
  VERSION = '0.0.1'
  PARAMS = {}

  if ARGV.any?
    require 'optparse'
    parser = OptionParser.new do |op|
      op.on('-p port', 'set the port (default is 3333)') do |port|
        PARAMS[:port] = port.to_i
      end
    end

    begin
      parser.parse!(ARGV.dup)
    rescue StandardError => e
      PARAMS[:error] = e
    end
  end

  module HTTPServer
    require 'socket'

    def listen(port, routes)
      tcp_server = TCPServer.new 'localhost', port
      loop do
        client = tcp_server.accept
        request = client.readpartial(2048)
        client.write handle_request(request, routes)
        client.close
      end
    end

    private

    def build_response(status:, content:)
      "HTTP/1.1 #{status}\r\n" \
      "Cache-Control: cache\r\n" \
      "X-Server: birth/#{Birth::VERSION}\r\n" \
      "Connection: close\r\n" \
      "Content-Type: text/html\r\n" \
      "#{content}"
    end

    def parse_request(request)
      # Request example:
      # GET / HTTP/1.1
      # Host: rawley.xyz
      # User-Agent: curl/7.49.1
      # Accept: */*

      split_request = request.lines[0].split

      {
        method: split_request[0],
        uri: split_request[1],
        version: split_request[2],
        headers: split_request[3..]
      }
    end

    def handle_request(request, routes)
      parsed_request = parse_request request

      uri, method, version = parsed_request[:uri], parsed_request[:method], parsed_request[:version]

      return build_response(**{ code: 404, content: '' }) if routes[uri.to_sym][method.to_sym].nil?
      return build_response(**{ code: 404, content: '' }) if version.split('/')[0] != 'HTTP'

      # Get the page from the route, read it, and build the response
      page_content = IO.read("html/#{routes[uri.to_sym][method.to_sym]}")
      response_data = { status: 200, content: page_content }
      build_response(**response_data)
    end
  end

  module MarkdownParser

  end

  remove_const(:PARAMS)
end
