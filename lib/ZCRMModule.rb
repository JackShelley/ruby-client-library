require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMModule

	attr_accessor :singular_label, :plural_label, :singular_label, :plural_label, :zclient, :should_refresh_metadata

	def initialize(zclient, hash_values={}, meta_folder="", api_name="", singular_label="", plural_label="")
		tokens = zclient.get_tokens
		if !tokens.is_refreshtoken_valid.nil? && !tokens.is_refreshtoken_valid then
			ZohoCRM_Client.log("Failed to initialize a new ZCRMModule object, because the zclient is not valid.")
			return nil
		end
		if hash_values.nil? || hash_values.empty? then
			return nil
		end
		hash_keys = hash_values.keys
		if !hash_keys.include?("api_name") || !hash_keys.include?("singular_label") || !hash_keys.include?("plural_label") then
			return nil
		end
		if api_name.nil? || api_name.empty? then
			api_name = hash_values["api_name"]
		end
		if singular_label.nil? || singular_label.empty? then
			singular_label = hash_values["singular_label"]
		end
		if plural_label.nil? || plural_label.empty? then
			plural_label = hash_values["plural_label"]
		end

		@zclient = zclient
		@api_name,@singular_label,@plural_label = api_name,singular_label, plural_label
		@hash_values = hash_values
		@meta_folder = meta_folder
		@should_refresh_metadata = false
		@fields = {}
		@required_fields = [] # Array of field ids
	end

	def is_creatable
		# We are writing these three functions.
		# Once this is written
		# We should handle upsert for Activities differently
		# We should check for creatable permission for modules before trying to create a record
		# What are the modules that have api permission?
		# What are the modules that have create permission?
		# What are the modules that do not have create permission?
		# What are the modules that do not have api permission?
		# We should try getting all of this from irb
		return @hash_values['creatable']
	end

	def is_editable
		return @hash_values['editable']
	end

	def is_deletable
		return @hash_values['deletable']
	end

	def is_viewable
		return @hash_values['viewable']
	end

	def get_field_names_as_array
		f_names = []
		@fields.each do |f_id, f|
			if f.class != ZCRMField then
				ZohoCRMClient.debug_log("Here's a problem ====> #{f}, #{f.class}")
				next
			end
			#ZohoCRMClient.debug_log("Printing field_id, field_obj ====> #{f_id} , #{f.class}, #{f}")
			f_names[f_names.length] = f.field_name
		end
		return f_names
	end

	#returns record_id
	def create_test_records(num)
		i = 0
		new_records = []
		req_fields = get_required_fields
		fields = get_fields
		while i < num do
			new_record = get_new_record
			fields.each do |id, field_obj|
				if req_fields.include? id || field_obj.is_required then
					field_name = field_obj.field_name
					value = ZCRMField.get_test_data(field_obj, @apiObj)
					new_record.set(field_name, value)
				end
			end
			new_records[new_records.length] = new_record
			i = i+1
		end
		bool, message, ids = upsert(new_records)
		return records.keys
	end

	def get_zclient
		return @zclient
	end

	def load_crm_module(module_name)
		return Api_Methods.load_crm_module(module_name, meta_folder)
	end

	#Points required for the function:
	#Checking activities currently:
		#For finding out what activity it is: Activity_Type
		#

	#Call_Duration - i
	#

	def get_related_list(rel_obj)
		#https://www.zohoapis.com/crm/v2/Leads/{record_id}/{Related_list_apiname}
		#params: record_id, Related_list_apiname [Part of the url]
		#module_data is not there for some related list modules,
			#In anitha's account: 
			#1_Zoho_Support
			#2_Social
			#3_Visits_Zoho_Livedesk
			#4_Zoho_Survey

		return_hash = {}
		rel_module_name = rel_obj.module_name
		rel_api_name = rel_obj.api_name
		is_rel_module = rel_obj.is_module


		mod_api_obj = nil
		if is_rel_module then
			mod_api_obj = load_crmmodule
		end
		url = Constants::DEF_CRMAPI_URL +URL_PATH_SEPERATOR+ @api_name +URL_PATH_SEPERATOR+ rel_obj.api_name
		headers = @zclient.construct_headers
		params = {}
		response = @zclient._get(url, params, headers)
		body = response.body
		records_json = Api_Methods._get_list(body, "data")
		records_json.each do |record|
			record_obj = nil
			if is_rel_module then
				record_obj = ZCRMRecord.new(rel_module_name, hash_values, mod_api_obj.get_fields)
				id = record_obj.record_id
			else
				record_obj = ZCRMRecord.new(rel_api_name, hash_values, nil)
				id = record_obj.record_id
			end
			return_hash[id] = record_obj
		end
		return return_hash
	end

	def module_list_from_local #to be finished after the current work
		return module_list
	end

	def related_list_hash
		return_hash = {}
		rel_arr = @hash_values['related_lists']
		rel_arr.each do |rel|
			api_name = rel['api_name']
			rel_obj = RelatedList.new(rel)
			return_hash[api_name] = rel_obj
		end
		return return_hash
	end

	def get_new_record
		r_fields = self.get_required_fields
		fields = self.get_fields
		new_record = ZCRMRecord.new(self.module_name, {}, fields, self)
		return new_record
	end

	def get_hash_values
		return @hash_values
	end

	def required_fields_test
		return @required_fields
	end

	def get_required_fields
		if @required_fields.empty? then
			self.populate_required_fields
			@required_fields.each do |f_id|
				fieldObj = @fields[f_id] 
				fieldObj.make_required
			end
		end
		return @required_fields
	end

	def populate_required_fields
		layouts = @hash_values['layouts']
		layouts.each do |layout_hsh|
			sections = layout_hsh["sections"]
			sections.each do |section_hsh|
				fields = section_hsh["fields"]
				fields.each do |field|
					required = field["required"]
					if required then
						field_id = field["id"]
						field_obj = @fields[field_id]
						field_obj.make_required
						@required_fields[@required_fields.length] = field_id
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
		if !fields.nil? && !fields.empty? then
			params['fields'] = fields.join(",")
		end
		if page > 1 then
			params['page'] = page
		end
		return params
	end

	def get_records(per_page=200, fields=[], page=1, sort_order='', approved=false, converted=false)
		#In case of invalid fields being present in the fields params passed, 
		#The invalid names will be 
		#ZohoCRMClient.debug_log("Inside get_records === > ")
		per_page_limit = 200 #TODO: need to confirm per_page limit

		#Default param values
		per_page_def = 200
		fields_def = []
		page_def = 1
		sort_order_def = ""
		approved_def = false
		converted_def = false

		#ZohoCRMClient.debug_log("Fields length ===> #{fields.length}")

		#Input validation
		per_page_fv = per_page_def
		if per_page.class == per_page_def.class then
			if per_page != 0 || !per_page > per_page_limit then
				per_page_fv = per_page
			end
		end
		fields_fv = []
		is_valid = false
		if fields.class == Array then
			is_valid = true
			fields.each do |fname|
				if fname.class != String then
					is_valid = false
				end
			end
		end
		if is_valid then
			f_names = self.get_field_names_as_array
			inv_names = []
			fields.each do |f|
				if !f_names.include? f then
					inv_names[inv_names.length] = f
					#fields.delete(f)
				end
			end
			if inv_names.length > 0 then
				ZohoCRMClient.log("The following invalid fields were present in given fields params. \n They are being returned. \n They are #{inv_names}. ")
				return inv_names
			else
				fields_fv = fields
			end
		else
			ZohoCRMClient.log("Given fields param had invalid values. Hence the fields params is not being populated. \n")
			fields_fv = fields_def
		end
		page_fv = 1
		if page.class == page_def.class then
			if page > 0 then
				page_fv = page
			end
		end
		sort_order_fv = ""
		if sort_order.class == sort_order_def.class then
			if sort_order == "asc" || sort_order == "desc" then
				sort_order_fv = sort_order
			else
				sort_order_fv = ""
			end
		end
		approved_fv = false
		if approved == true || approved == false then
			approved_fv = approved
		end
		converted_fv = false
		if converted == true || converted == false then
			converted_fv = converted
		end

		records = {}
		url = Constants::DEF_CRMAPI_URL + self.module_name
		params = construct_GET_params(sort_order_fv, per_page_fv, approved_fv, converted_fv, fields_fv, page_fv)
		#ZohoCRMClient.debug_log("fields passed ===> #{fields_fv.join(",")}")
		#ZohoCRMClient.debug_log("The params passed ===> #{params}")
		headers = @zclient.construct_headers
		#response = @zclient._get(url, params, headers)
		response = @zclient.safe_get(url, params, headers)
		if response.nil? then
			ZohoCRMClient.debug_log("Response is nil ==> we need to raise exception in this place ==> ")
			raise "400 Bad Request Exception"
		end
		body = response.body
		records_json = Api_Methods._get_list(body, "data")
		records_json.each do |record_hash|
			record_obj = ZCRMRecord.new(self.module_name, record_hash, @fields)
			id = record_obj.record_id
			records[id] = record_obj
		end
		#Checking to see if there's a change in the field list
=begin
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
=end
		return records
	end

	def update_records(records={})
		if records.empty? then
			return false, "No Record to update"
		end
		url = Constants::DEF_CRMAPI_URL + self.module_name

		headers = @zclient.construct_headers
		temp = []
		failed_ids = []
		records.each do |id, record|
			bool,update_hash = record.construct_update_hash
			if bool then
				temp[temp.length] = update_hash
			else
				ZohoCRMClient.debug_log("Not_updated_id ====> #{id}")
				failed_ids[failed_ids.length] = id
			end
		end
		final_hash = {}
		final_hash['data'] = temp
		update_json=JSON.generate(final_hash)
		ZohoCRMClient.debug_log("Update json ===> #{update_json}")
		response = @zclient._update_put(url, headers, update_json)
		body = response.body
		ZohoCRMClient.debug_log("Printing response body ===> #{body}")
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
		if !self.is_creatable then
			if self.is_editable then
				return false, Constants::USE_UPDATE_FUNC, []
			else
				return false, Constants::MODULE_DOESNT_SUPPORT_CREATE, []
			end
		end
		if records.nil? || records.empty? then
			return false, Constants::EMPTY_RECORDS_MSG, []
		end
		url = Constants::DEF_CRMAPI_URL + self.module_name
		failed_records = []
		jsons = []
		records.each do |record|
			success, update_hash = record.construct_upsert_hash
			if success then
				jsons[jsons.length] = update_hash
			else
				failed_records[failed_records.length] = record
			end
		end
		if failed_records.length > 0 then
			return false, Constants::MAND_FIELDS_NOT_SET, failed_records
		else
			ZohoCRMClient.log("All records have their mandatory fields set. Hence continuing with upsert. ")
		end
		entire_json = {}
		entire_json['data'] = jsons
		update_json = JSON::generate(entire_json)
		print "Printing update_json. ", "\n"
		print update_json, "\n"
		headers = @zclient.construct_headers
		ZohoCRMClient.debug_log("The upsert call url ===> #{url}")
		response = @zclient._upsert_post(url, {}, headers, update_json)
		ZohoCRMClient.debug_log("Response for upsert call ===> #{response}")

		#response = zclient._post(url, {}, headers)
		code = response.code.to_i
		if code == 401 then
			temp = @zclient.revoke_token
			if !temp then
				raise InvalidTokensError
			end
			headers = @zclient.construct_headers
			response = @zclient._upsert_post(url, {}, headers, update_json)
		end
		code = response.code.to_i
		if code == 401 then
			raise InvalidTokensError
		end
		body = response.body
		print "Printing body ","\n"
		print body, "\n"
		returned_records = Api_Methods._get_list(body, "data")
		s_ids = []
		f_ids = []
		returned_records.each do |rec_obj|
			code = rec_obj['code']
			details = rec_obj['details']
			id = details['id']
			if code.downcase == "success" then
				s_ids[s_ids.length] = id
			else
				f_ids[f_ids.length] = id
			end
		end
		if s_ids.length == records.size then
			return true, Constants::GENERAL_SUCCESS_MESSAGE, s_ids
		else
			return false, Constants::UPSERT_FAIL_MESSAGE, s_ids
		end
	end

	def delete_records(ids=[])
		if id.nil? then
			return false,[]
		end
		if id.empty? then
			return false, []
		end
		#https://www.zohoapis.com/crm/v2/
		url = Constants::DEF_CRMAPI_URL + self.module_name
		print "Url ===> ", url, "\n"
		number_of_ids = ids.length
		cntr = 1

		ids_param = ids.join(',')
		params = {}
		params['ids'] = ids_param
		headers = @zclient.construct_headers
		response = @zclient._delete(url, params, headers)
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
	def get_record(id="")
		if id.nil? then
			return nil
		end
		if id.empty? then
			return nil
		end
		#https://www.zohoapis.com/crm/api/v2/{Module}/{Id}
		url = Constants::DEF_CRMDATA_API_URL + self.module_name + "/" + id
		headers = @zclient.construct_headers
		response = @zclient._get(url, {}, headers)
		code = response.code
		if code == 204 then
			ZohoCRM_Client.log("There is no data for id "+id+" for module "+module_name)
			return nil
		end
		body = response.body
		list = ApiMethods._get_list(body, "data")
		record = list[0]
		result = ZCRMRecord.new(self.module_name, record, @fields)
		return result
	end

	def update_record(record)
		update_hash = record.construct_update_hash
		id = record.record_id
		url = Constants::DEF_CRMDATA_API_URL + self.module_name + "/" + id
		headers = @zclient.construct_headers
		response = @zclient._put(url, {}, headers)
		body = response.body
		temp = ApiMethods._get_list(body, "data")
		returned_record = temp[0]
		record.record_error_fields(returned_record)
		return record
	end

	def delete(record_id)
		#https://www.zohoapis.com/crm/v2/{Module}/{EntityID}
		url = Constants::DEF_CRMAPI_URL + URL_PATH_SEPERATOR + module_name + URL_PATH_SEPERATOR + record_id
		headers = @zclient.construct_headers
		response = @zclient._delete(url, {}, headers)
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
		Meta_data.module_data(@zclient, self.module_name, @meta_folder)
	end

	def populate_metadata_from_local
		load_crmmodule(module_name, @meta_folder)
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
		if field.class != ZCRMField then
			return false
		end
		id = field.field_id
		@fields[id] = field
	end

	def set_fields(fields_obj)
		@fields = fields_obj
	end

	#private :populate_required_fields
end

class RelatedList
	def initialize(json_hash)
		@display_label = json_hash['display_label']
		@visible = json_hash['visible']
		@api_name = json_hash['api_name']
		@module = json_hash['module']
		@name = json_hash['name']
		@id = json_hash['id']
		@href = json_hash['href']
		@type = json_hash['type']
		if @href.nil? then
			@is_module = false
		else
			@is_module = true
		end
	end
	def api_name
		return @api_name
	end
	def is_module
		return @is_module
	end
end