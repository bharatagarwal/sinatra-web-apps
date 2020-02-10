require 'socket'

server = TCPServer.new('localhost', 3003)

loop do
  client = server.accept

  request = ''
  content_length = nil
  body = ''
  
  loop do
    line = client.gets
    request << line  

    content_length = line.split(": ")[1].to_i if line.include?("Content-Length")
    
    if line == "\r\n"
      body = client.readpartial(content_length) if request.include?("Content-Length")
      break
    end
  end

  puts request
  puts body unless body.empty?

  client.puts "response"
  client.close
end