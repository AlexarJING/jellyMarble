local net={}
local socket=require "socket"
function net:init()
	self.server=lube.udpServer()
	self.server:createSocket()
	self.server.port = 42069
	self.server:_listen()
	self.toSend={}
	self.toGet={}
	self.clientID=nil
	self.timeOut=3000
end

function net:getIP()
	return socket.dns.toip(socket.dns.gethostname())
end


function net:update(dt)
	self.toGet={}
	local data, id = self.server:receive() -- snatch that naughty client data up | id = "ip:port"
	if not self.clientID then
		self:clientRepo(data,id)
	end
	if data and self.clientID==id then
		self.timeOut=3000
		self.toGet = {id=id,msg=bin:unpack(data)} -- unpack received data from string to array
	end
	if self.clientID and self.toSend[1] then
		for i,v in ipairs(self.toSend) do
			self.server:send(bin:pack(v),self.clientID)
		end
		self.toSend={}
	end
	self.timeOut=self.timeOut-1
	if self.timeOut<0 and self.clientID then 
		self.clientID=nil
		print("lost client connection")
	end
end



function net:clientRepo(data,id)
	if id~="No message." then
		self.clientID=id
		self.server:send(bin:pack({"im here"}), id)
	end
end



return net