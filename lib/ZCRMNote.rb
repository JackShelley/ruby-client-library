require 'ZohoCRM_Client'

class ZCRMNote
	def initialize(note_hash={})
		@id = note_hash["id"]
		@owner = note_hash["Owner"]
		@note_title = note_hash["Note_Title"]
		@note_content = note_hash["Note_Content"]
		@parent = note_hash["Parent_Id"]
		@parent_module = note_hash["$se_module"]
		@updated_fields = []
		@hash_values = note_hash
	end
	def id
		return @id
	end
	def note_title
		return @note_title
	end
	def note_content
		return @note_content
	end
	def get_parent_name
		return @parent["name"]
	end
	def get_parent_id
		return @parent["id"]
	end
	def get_parent_hash
		return @parent
	end
	def get_owner_hash
		return @owner
	end
	def get_owner_id
		return @owner["id"]
	end
	def get_owner_name
		return @owner["name"]
	end
	def note_data
		return @hash_values
	end
	def update_title(title)
		if !title.nil? && !title.empty? then
			@note_title = title
			if !@updated_fields.include? :title then
				@updated_fields[@updated_fields.length] = :title
			end
		end
	end
	def update_content(content)
		if !content.nil? && !content.empty? then
			@note_content = content
			if !@updated_fields.include? :content then
				@updated_fields[@updated_fields.length] = :content
			end
		end
	end
	def construct_update_hash
		result = {}
		if !@note_title.nil? && !@note_title.empty? then
			result["Note_Title"] = @note_title
		end
		result["Note_Content"] = @note_content
		result["id"] = @id
		ZohoCRMClient.debug_log("Update hash ==> #{result}")
		return result
	end


	#todo: get and return from json_hash
	def created_by
	end
	def modified_by
	end
	def created_time
	end
	def modified_time
	end
end