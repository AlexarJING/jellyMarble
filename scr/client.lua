local net={}
function net:init()
	self.client = lube.udpClient()
	self.client:createSocket()
	self.client.host = "127.0.0.1"
	self.client.port = 42069
	self.client.connected = true
	self.toSend={}
	self.toGet={}
	self.askTime=100
	self.linked=false
	self.timeOut=3000
end

function net:update(dt)
	self.toGet={}
	if not self.linked then
		self.askTime = self.askTime-1
		if self.askTime<0 then
			print("no server")
			self.askTime=100
		end
		self.client:_send(bin:pack({"hello"}))
	end

	local data = self.client:_receive()
	if data then
		self.timeOut=3000
		self.linked=true
		self.toGet = {id="server",msg=bin:unpack(data)}
	end


	if self.toSend[1] then
		for i,v in ipairs(self.toSend) do
			self.client:_send(bin:pack(v))
		end
		self.toSend={}
	end


	self.timeOut=self.timeOut-1
	if self.timeOut<0 then self.linked=false end
end



return net