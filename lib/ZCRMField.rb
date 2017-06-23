require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMField
	@@field_attributes = ["visible", "json_type", "field_label", "length", "tooltip", "view_type", "created_source", "read_only" ]

	attr_accessor  :api_name, :field_label, :json_type, :data_type, :custom_field, :is_picklist, :hash_values

	def initialize(api_name, field_label, json_type=:string, data_type=:text, custom_field=false, is_picklist=false, hash_values={})
		@api_name = api_name
		@field_label = field_label
		@json_type = json_type
		@data_type = data_type
		@custom_field = custom_field
		@is_picklist = is_picklist
		@hash_values = hash_values
		@is_mandatory = true
	end

	def field_name
		return @api_name
	end

	def field_id
		return hash_values['id']
	end

	def get(key)
		return hash_values[key]
	end

	def get_datatype
		return @data_type
	end
	
	def get_formula
		data_type = get_datatype
		if data_type != 'formula' then
			return true, get('formula')
		else
			return false, "Something success"
		end
	end

end