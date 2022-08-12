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

      op.on('-l location', 'set the location to look for markdown files, and to generate html files') do |location|
        PARAMS[:location] = location
      end
    end

    begin
      parser.parse!(ARGV.dup)
    rescue StandardError => e
      PARAMS[:error] = e
    end

    PARAMS[:location] ||= __dir__
    PARAMS.freeze
  end

  class << self
    def run
      routes = MarkdownParser.generate_routes PARAMS[:location]
      start routes
    end

    def start(routes)
      puts "Starting birth. On port #{port}"
      Thread.new { HTTPServer.listen PARAMS[:port] || 3000, routes }
    end
  end

  module HTTPServer
    module Logger
      class << self
        def log_request(method, uri)
          puts "REQUEST #{method} | #{uri}"
        end

        def log_response(status, page)
          puts "RESPONSE #{status} #{RESPONSE_TEXT[status]} -> #{page}"
        end
      end
    end

    RESPONSE_TEXT = {
      200 => 'OK',
      404 => 'Not Found',
      405 => 'Bad Request',
      500 => 'Internal Server Error'
    }.freeze

    class << self
      def listen(port, routes)
        require 'socket'

        tcp_server = TCPServer.new 'localhost', port
        loop do
          client = tcp_server.accept
          request = client.readpartial(2048)
          begin
            client.write handle_request(request, routes)
          rescue StandardError => e
            puts e.message
            client.write build_response(status: 500)
          end
          client.close
        end
      end

      private

      def build_response(response)
        "HTTP/1.1 #{response[:status]} #{RESPONSE_TEXT[response[:status]]}\r\n" \
        "Cache-Control: cache\r\n" \
        "Date: #{Time.now}\r\n" \
        "X-Server: birth/#{Birth::VERSION}\r\n" \
        "Connection: keep-alive\r\n" \
        "Content-Type: text/html; charset=iso-8859-1\r\n" \
        "Content-Length: #{response[:content].to_s.length}\r\n" \
        "\r\n" \
        "#{response[:content]}"
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
          headers: request.lines[3..]
        }
      end

      def handle_request(request, routes)
        parsed_request = parse_request request
        uri, method, version = parsed_request[:uri], parsed_request[:method], parsed_request[:version]

        Logger.log_request method, uri

        return build_response(code: 404, content: routes[uri]) if routes[uri].nil?
        return build_response(code: 405) if version.split('/')[0] != 'HTTP'

        # Get the page from the route, read it, and build the response
        page_content = IO.read("#{routes[:uri]}.html")
        response_data = { status: 200, content: page_content }
        build_response(response_data)
      end
    end

    module MarkdownParser
      require 'commonmarker'
      class << self
        def generate_routes
          require 'fileutils'

          location = Birth::PARAMS[:location]
          t = location.split('/')
          html_location = t.first(t.size - 1)
                         .join('/')
                         .concat('/html')
          FileUtils.mkdir_p html_location

          files = Dir["#{location}/**/*.md"].select { File.file? _1 }

          routes = {}
          files.each do |file|
            html = parse_file file
            html_file = "#{html_location}/#{convert_path_to_html file}"
            File.open(html_file).write(html).close
            if file.end_with? 'index.html'
              routes['/'] = html_file
            else
              routes[file] = html_file
            end
          end
        end

        private

        def convert_path_to_html(path)
          post_md = path
        end

        def parse_file(path)
          CommonMarker.render_doc(File.read(path), :DEFAULT).to_html
        end
      end
    end
  end
end
