require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMModule

	attr_accessor :singular_label, :plural_label, :singular_label, :plural_label, :zclient, :should_refresh_metadata

	def initialize(zclient, api_name, singular_label, plural_label, hash_values, meta_folder)
		@zclient = zclient
		@api_name,@singular_label,@plural_label = api_name,singular_label, plural_label
		@hash_values = hash_values
		@meta_folder = meta_folder
		@should_refresh_metadata = false
		@fields = {}
		@mandatory_fields = [] # Array of field ids
	end

	def get_hash_values
		return @hash_values
	end

	def get_mandatory_fields
		if @mandatory_fields.empty? then
			populate_mandatory_fields
		end
		return @mandatory_fields
	end

	def populate_mandatory_fields
		required_fields = []
		layouts.each do |layout_hsh|
			sections = layout_hsh["sections"]
			sections.each do |section_hsh|
				fields = section_hsh["fields"]
				fields.each do |field|
					required = field["required"]
					if required then
						field_id = field["id"]
						@mandatory_fields[@mandatory_fields.length] = field_id
					end
				end
			end
		end
	end

	def construct_GET_params(sort_order, per_page, approved, converted, fields, page)
		params={}
		if !sort_order.empty? then
			params['sort_order'] = 'asc'
		end
		if per_page!=200 then
			params['per_page'] = per_page
		end
		if approved then
			params['approved'] = approved
		end
		if converted then
			params['converted'] = converted
		end
		if fields.nil? then
			params['fields'] = fields
		end
		if page > 1 then
			params['page'] = page
		end
		return params
	end

	def get_records(per_page=200, fields=[], page=1, sort_order='', approved=false, converted=false)
		#https://www.zohoapis.com/crm/api/v2/{Module}
		records = {}
		url = Constants::DEF_CRMAPI_URL + self.module_name
		print url, '/n'
		params = construct_GET_params(sort_order, per_page, approved, converted, fields, page)
		print params, '/n'
		headers = zclient.construct_headers
		print headers, '/n'
		response = zclient._get(url, params, headers)
		body = response.body
		records_json = Api_Methods._get_list(body, "data")
		records_json.each do |record_hash|
			record_obj = ZCRMRecord.new(self.module_name, record_hash, @fields)
			id = record_obj.record_id
			records[id] = record_obj
		end
		#Checking to see if there's a change in the field list
		first_record = records[records.keys[0]]
		if !@should_refresh_metadata then
			@should_refresh_metadata = first_record.check_fields
		end
		if @should_refresh_metadata then 
			temp = self.rebuild_moduledata
			if temp then
				@should_refresh_metadata = false
			end
		end
		return records
	end

	def update_records(records={})
		if records.empty? then
			return false, "No Record to update"
		end
		url = Constants::DEF_CRMAPI_URL + self.module_name
		print "Url ===> ", url

		headers = zclient.construct_headers
		temp = []
		records.each do |id, record|
			update_hash = record.construct_update_hash
			temp[temp.length] = update_hash
		end
		final_hash = {}
		final_hash['data'] = temp
		print "Final_hash ", "\n"
		print final_hash, "\n"
		update_json=JSON.generate(final_hash)
		response = zclient._update_put(url, {}, headers, update_json)
		body = response.body
		print "Printing response body ===> ", "\n"
		print body, "\n"
		returned_records = Api_Methods._get_list(body, "data")
		success_ids = []
		failed_ids = []
		returned_records.each do |ret|
			code = ret['code']
			details = ret['details']
			ret_id = details['id']
			if code == "SUCCESS" then
				success_ids[success_ids.length] = ret_id
			else
				failed_ids[failed_ids.length] = ret_id
			end
		end
		return success_ids, failed_ids
	end

	def upsert(records=[]) #records => Array of ZCRMRecord objects
		failed_records = []
		jsons.each do |json|
			json['each'] = json
		end
		records.each do |record|
			success, update_hash = record.construct_upsert_hash
			if success then
				jsons[jsons.length] = update_hash
			else
				failed_records[failed_records.length] = record
			end
		end
		entire_json = {}
		entire_json['data'] = records
		update_json = JSON::generate(entire_json)
		response = zclient._post(url, {}, headers)
		body = response.body
		returned_records = Api_Methods._get_list(body)
		returned_records.each do |ret|
			ret_id = ret['id']
			record = records[ret_id]
			record.record_error_fields(ret)
		end
	end

	def delete_records(ids=[])
		#https://www.zohoapis.com/crm/v2/
		url = Constants::DEF_CRMAPI_URL + self.module_name
		print "Url ===> ", url, "\n"
		number_of_ids = ids.length
		cntr = 1

		ids_param = ids.join(',')
		params = {}
		params['ids'] = ids_param
		headers = zclient.construct_headers
		response = zclient._delete(url, params, headers)
		body = response.body
		print "Printing response body ::: ", "\n"
		print body, "\n"
		data = Api_Methods._get_list(body, "data")
		success_ids = []
		failure_ids = []
		data.each do |json|
			code = json['code'].downcase
			id = json['details']['id']
			if code == "success" then
				success_ids[success_ids.length] = id
			else
				failure_ids[failure_ids.length] = id
			end
		end
		if failure_ids.length>0 then
			return false, failure_ids
		else
			return true, failure_ids
		end
	end

	#Single record apis
	def get_record(id)
		#https://www.zohoapis.com/crm/api/v2/{Module}/{Id}
		url = Constants::DEF_CRMDATA_API_URL + self.module_name + "/" + id
		headers = zclient.construct_headers
		response = zclient._get(url, {}, headers)
		body = response.body
		list = ApiMethods._get_list(body, "data")
		record = list[0]
		result = ZCRMRecord.new(self.module_name, record, @fields)
		return result
	end

	def update_record(record)
		update_hash = record.construct_update_hash
		url = Constants::DEF_CRMDATA_API_URL + self.module_name + "/" + id
		headers = zclient.construct_headers
		response = zclient._put(url, {}, headers)
		body = response.body
		temp = ApiMethods._get_list(body, "data")
		returned_record = temp[0]
		record.record_error_fields(returned_record)
		return record
	end

	def delete(record_id)
		#https://www.zohoapis.com/crm/v2/{Module}/{EntityID}
		url = Constants::DEF_CRMAPI_URL + URL_PATH_SEPERATOR + module_name + URL_PATH_SEPERATOR + record_id
		headers = zclient.construct_headers
		response = zclient._delete(url, {}, headers)
		body = response.body
		temp = ApiMethods._get_list(body, "data")
		json = temp[0]
		code = json.code
		id = json['details'].id
		if id == record_id then
			return true 
		else
			return false
		end
	end



	def rebuild_moduledata
		Meta_data.module_data(zclient, self.module_name, @meta_folder)
	end
	def populate_metadata_from_local
		load_crmmodule(module_name, @meta_folder)
	end

	def get_whole_module_json(module_name)
		return @hash_values
	end

	def module_name
		return @api_name
	end

	def get_fields
		return @fields
	end

	def add_field(field=nil)
		if field.nil? then
			return false
		end
		id = field.field_id
		@fields[id] = field
	end

	def set_fields(fields_obj)
		@fields = fields_obj
	end

	private :populate_mandatory_fields
end