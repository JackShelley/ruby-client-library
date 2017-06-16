require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class zcrmmodule

	@fields = {}
	attr_accessor :singular_label, :plural_label, :singular_label, :plural_label, :zclient, :should_refresh_metadata

	def initialize(zclient, api_name, singular_label, plural_label, hash_values, meta_folder)
		@zclient = zclient
		@api_name,@singular_label,@plural_label = api_name,singular_label, plural_label
		@hash_values = hash_values
		@meta_folder = meta_folder
		@should_refresh_metadata = false
	end

	def construct_GET_params(sort_order, per_page, approved, converted, fields, page)
		params={}
		if !sort_order.empty? then
			params['sort_order'] = 'asc'
		end
		if per_page>1 then
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
		if per_page != 200 then
			params['per_page'] = per_page
		end
		return params
	end

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

	def update_record(id)

	end

	def get_records(sort_order='', per_page='200', approved=false, converted=false, fields=[], page=1)
		#https://www.zohoapis.com/crm/api/v2/{Module}
		records = {}
		url = Constants::DEF_CRMDATA_API_URL + self.module_name
		params = construct_params(sort_order, per_page, approved, converted, fields, page)
		headers = zclient.construct_headers
		response = zclient._get(url, params, headers)
		body = response.body
		records_json = ApiMethods._get_list(body, "data")
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
			temp = self.rebuild_metadata
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
		url = Constants::DEF_CRMDATA_API_URL + module_name
		headers = zclient.construct_headers
		temp = []
		records.each do |record|
			update_hash = record.construct_update_hash
			temp[temp.length] = update_hash
		end
		final_hash = {}
		final_hash['data'] = temp
		update_json=JSON.generate(final_hash)
		##Here you should make the api call
		response = zclient._post() # Call the appropriate function and pass in the appropriate params
		body = response.body
		returned_records = ApiMethods._get_list(body)
		returned_records.each do |ret|
			ret_id = ret['id']
			record_obj = records[ret_id]
			record_obj.record_error_fields(ret)
		end
		if @should_refresh_metadata then
			temp = self.rebuild_metadata
			if temp then 
				@should_refresh_metadata = false
			end
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

	def add_field(field=nil)
		if field.nil? then
			return false
		end
		id = field.field_id
		fields[id] = field
	end

	def set_fields(fields_obj)
		@fields = fields_obj
	end
end