local packets = {}

local byteNet = require(game:GetService("ReplicatedStorage"):WaitForChild("Helpers"):WaitForChild("ByteNet"))

packets.BulletCreation = byteNet.defineNamespace("BulletCreation", function()
	return {
		BulletCreation = byteNet.definePacket({
			value = byteNet.struct({
					Setting = byteNet.string,
					Index = byteNet.uint32,
					Position = byteNet.optional(byteNet.string),
					EndPosition = byteNet.optional(byteNet.string),
					Speed = byteNet.optional(byteNet.uint16),
					Rotation = byteNet.optional(byteNet.string),
			}),
			
			reliabilityType = "reliable"
		})
	}
end)

return packets
