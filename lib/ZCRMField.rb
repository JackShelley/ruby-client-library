require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMField
	@@field_attributes = ["visible", "json_type", "field_label", "length", "tooltip", "view_type", "created_source", "read_only" ]

	attr_accessor  :api_name, :field_label, :json_type, :data_type, :custom_field, :is_picklist, :hash_values, :is_required, :picklist_values

	def initialize(api_name, field_label, json_type=:string, data_type=:text, custom_field=false, is_picklist=false, hash_values={})
		@api_name = api_name
		@field_label = field_label
		@json_type = json_type
		@data_type = data_type
		@custom_field = custom_field
		@is_picklist = is_picklist
		@hash_values = hash_values
		@is_required = false
		@picklist_values = []
	end

	def self.get_test_data(field_obj, apiObj)
		field_name = field_obj.field_name
		f_id = field_obj.field_id
		data_type = field_obj.get_datatype
		value = nil
		if data_type == "text"
			value = "Non_empty_text"
		elsif data_type == "integer"
			value = 100
		elsif data_type == "picklist"
			picklist_values = field_obj.get_picklist_values
			pick_value = picklist_values[0]
			value = pick_value['actual_value']
		elsif data_type == "ownerlookup"
			userId = userObj.keys[0]
			value = userId
		elsif data_type == "currency"
			value = 7
		elsif data_type == "phone"
			value = "1234567890"
		elsif data_type == "email"
			value = randomemail@hotmail.com
		elsif data_type == "website"
			value = "google.come"
		elsif data_type == "boolean"
			value = true
		elsif data_type == "string"
			value = "Non_empty_string"
		elsif data_type == "date"
			#Format for date : (%Y-%m-%d)
			d = DateTime.now
			cur_date = d.strftime("%Y-%m-%d")
			next_month_date = d.next_month.strftime("%Y-%m-%d")
			value = next_month_date
		elsif data_type == "multiselectpicklist"
			res = []
			picklist_values = field_obj.get_picklist_values
			pick_value = picklist_values[0]
			temp = pick_value['actual_value']
			res[0] = temp
			pick_value = picklist_values[1]
			temp = pick_value['actual_value']
			res[1] = temp
			value = res
		elsif data_type == "datetime"
			#TODO: Find out the format for datetime
			#Format for datetime : (%Y-%m-%dT%H:%M:%S+05:30)
			#Sample datetime from get_records api response 2010-05-07T20:10:00+05:30

			d = DateTime.now
			cur_date = d.strftime("%Y-%m-%dT%H:%M:%S+05:30")
			next_month_date = d.next_month.strftime("%Y-%m-%dT%H:%M:%S+05:30")
			value = next_month_date
		elsif data_type == "textarea"
			value = "Non_empty_textarea"
		elsif data_type == "double"
			value = 10.2
		elsif data_type == "bigint"
			value = 10000000000
		elsif data_type == "lookup"
			lookup_json = field_obj.get("lookup")
			values = field_obj.get_hash_values

			temp_json = JSON.generate(values)
			temp_fp = "/Users/kamalkumar/test/temp_file.json"
			temp_file = open(temp_fp, 'w')
			temp_file.write(temp_json)

			module_name = lookup_json['module']
			if module_name == "se_module" then
				module_name = "Leads"
			end
			obj = apiObj.load_crm_module(module_name)
			records = obj.get_records(1)
			lookup_id = records.keys[0]
			value = lookup_id
		end
		return value
	end

	def get_hash_values
		return @hash_values
	end

	def make_required
		@is_required = true
	end

	def is_required
		return @is_required
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

	def get_picklist_values
		return @picklist_values
	end

	def set_picklist_values(values)
		@picklist_values = values
	end
end