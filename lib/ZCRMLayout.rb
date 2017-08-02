require 'ZohoCRM_Client'

class ZCRMLayout
	#attr_accessor :id, :name, :profiles, :is_default, :field_ids, :req_field_ids, :layout_hash
	def initialize(layout_hash)
		@id = layout_hash["id"]
		@name = layout_hash["name"]
		@profiles = layout_hash["profiles"]
		@status = layout_hash["status"] #todo: We may need status in the future. Test and add if we need
		if @status == 0 then
			@is_default = true
		else 
			@is_default = false
		end
		@field_ids, @req_field_ids = fields_and_reqfields(layout_hash)
		@layout_hash = layout_hash
	end

	def fields_and_reqfields(layout_hash)
		fields_ids = []
		req_field_ids = []

		sections = layout_hash["sections"]
		sections.each do |section|
			fields = section["fields"]
			fields.each do |field|
				id = field["id"]
				required = field["required"]
				if required then
					req_field_ids[req_field_ids.length] = id
				end
				fields_ids[fields_ids.length] = id
			end
		end
		return fields_ids, req_field_ids
	end

	def status
		return @status
	end

	def name
		return @name
	end

	def id
		return @id
	end

	def is_default
		return @is_default
	end

	def profiles
		return @profiles
	end

	def field_ids
		return @field_id
	end

	def req_field_ids
		return @req_field_ids
	end

	def get_hash_values
		return @layout_hash
	end

end