require "ZohoCRM_Client"

class ZCRMAttachment
	def initialize(json_hash)
		@id = json_hash["id"]
		@size = json_hash["Size"]
		@file_name = json_hash["File_Name"]
		@parent_hash = json_hash["Parent_Id"]
		@owner_hash = json_hash["Owner"]
		@parent_module = json_hash["$se_module"]
		@hash_values = json_hash
	end
	def id
		return @id
	end
	def size
		return @size
	end
	def parent_module
		return @parent_module
	end
	def parent_id
		return @parent_hash["id"]
	end
	def parent_name
		return @parent_hash["name"]
	end
end