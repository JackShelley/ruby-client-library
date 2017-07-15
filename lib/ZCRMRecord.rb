require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMRecord


	def initialize(module_name, hash_values, fields, mod_obj=nil)
		@module_name = module_name
		@hash_values = hash_values
		@fields = fields
		@modified_fields = {}
		@added_fields = {}
		@unavailable_fields = []
		@fields_sent_lastupdate = []
		@error_fields_lastupdate = []
		@is_deleted = false
		@is_record_marked_for_deletion = false
		if !hash_values.nil? then
			@record_id = hash_values['id']
		else
			@record_id = nil
		end
		@required_fields = []
		@module_obj = mod_obj
	end

	def get_hash_values
		return @hash_values
	end

	def check_module_obj
		if @module_obj.nil? then
			return false
		else
			return true
		end
	end
	
	def get_attachments
		#Url: https://www.zohoapis.com/crm/v2/{module}/{record_id}/Attachments
		if @module_obj.nil? then
			print "Please set module object before proceeding ::" + @module_obj
			return false, {}
		end
		url = Constants::DEF_CRMAPI_URL + @module_name + Constants::URL_PATH_SEPERATOR + self.record_id + Constants::URL_PATH_SEPERATOR + "Attachments"
		zclient = @module_obj.get_zclient
		headers = zclient.headers
		params = {}
		response = zclient.get(url, params, headers)
		body = response.body
		list = Api_Methods._get_list(body, "data")
		result_data = {}
		list.each do |json|
			id = json['id']
			result_data[id] = json
		end
		return result_data
	end

	def upload_attachment
		#url: https://www.zohoapis.com/crm/v2/Leads/1000000231009/Attachments
		if check_module_obj then
			print "Please set module_obj and proceed ::: "
		end
		url = Constants::DEF_CRMAPI_URL + @module_name + Constants::URL_PATH_SEPERATOR + self.record_id + Constants::URL_PATH_SEPERATOR + "Attachments"
		zclient = @module_obj.get_zclient
		headers = zclient.headers
		params = {}
		response = zclient.put(url, params, headers)
		body = response.body
		list = Api_Methods._get_list(body, "data")
		failed_ids = []
		success_ids = []
		list.each do |json|
			json.each do |json|
				code = json['code']
				details = json['details']
				id = details['id']
				if code == "SUCCESS" then
					success_ids[success_ids.length] = id
				else
					failed_ids[failed_ids.length] = id
				end
			end
		end
		if failed_ids.length > 0 then
			return false, failed_ids
		else
			return true, failed_ids
		end
	end

	def upload_photo
	end

	def download_photo
	end

	def update_note(note_title="", note_content="")
		if @module_obj.nil? then
			print "Please set module_obj for the record and proceed ::: "
			return false
		end
		note_json = {}
		note_json['Note_Title'] = note_title
		note_json['Note_Content'] = note_content
		arr = []
		arr[0] = note_json
		final_hash = {}
		final_hash['data'] = arr
		json = JSON::generate(final_hash)
		url = Constants::DEF_CRMAPI_URL + @module_name + URL_PATH_SEPERATOR + self.record_id + URL_PATH_SEPERATOR + "Notes"
		zclient = @module_obj.get_zclient
		headers = zclient.construct_headers
		params = {}
		response = zclient._update_put(url, headers, payload)
		body = response.body
		notes = Api_Methods._get_list(body,"data")
		failed_ids = []
		success_ids = []
		notes.each do |note|
			code = note['code']
			details = note['details']
			id = details['id']
			if code == "SUCCESS" then
				success_ids[success_ids.length] = id
			else
				failed_ids[failed_ids.length] = id
			end
		end
		if failed_ids.length > 0 then
			return false, failed_ids
		else
			return true, []
		end
	end

	def create_note(note_title="", note_content="") ## Pending completion : Will do that once Im done update related records
		if @module_obj.nil? then
			print "Please set module_obj for the record and proceed ::: "
			return false
		end
		note_json = {}
		note_json['Note_Title'] = note_title
		note_json['Note_Content'] = note_content

		arr = []
		arr[0] = note_json
		final_hash = {}
		final_hash['data'] = arr
		json = JSON::generate(final_hash)
		#https://www.zohoapis.com/crm/v2/{Module}/{record_id}/Notes
		url = Constants::DEF_CRMAPI_URL + @module_name + URL_PATH_SEPERATOR + self.record_id + URL_PATH_SEPERATOR + 'Notes' 
		zclient = @module_obj.get_zclient
		headers = zclient.construct_headers
		params = {}
		response = zclient._upsert_post(url, params, headers, json)
		body = response.body
		notes = Api_Methods._get_list(body, "data")
		created_note_ids = []
		notes.each do |note_json|
			code = note_json['code']
			details = note_json['details']
			note_id = note_json['id']
			if code == "SUCCESS" then
				created_note_ids[created_note_ids.length] = note_id
			end
		end
		return created_note_ids
	end

	def update_related_record(related_record_obj)
		#Returns : boolean,Array of failed ids [Array]
		#https://www.zohoapis.com/crm/v2/Leads/{record_id}/Campaigns/{related_record_id}
		if @module_obj.nil? then
			print "Please set module_obj and proceed ::: "
			return false, []
		end

		related_module = related_record_obj.module_name

		if not (related_module == "Campaigns" || related_module == "Products")
			print "Please check the related module and continue again ::: "
		else
			print "The related list module is all fine, you can continue ::: "
		end

		related_record_id = related_record_obj.record_id
		record_id = self.record_id
		url = Constants::DEF_CRMAPI_URL + @module_name + URL_PATH_SEPERATOR + self.record_id + URL_PATH_SEPERATOR + related_module + URL_PATH_SEPERATOR + related_record_id
		zclient = @module_obj.get_zclient
		headers = zclient.construct_headers
		params = {}
		json = related_record_obj.construct_update_hash
		json_arr = []
		json_arr[0] = json
		final_hash = {}
		final_hash['data'] = json_arr
		final_json = JSON::generate(final_hash)
		response = zclient._put(url, {}, headers, final_json)
		body = response.body
		json_list = Api_Methods._get_list(body, "data")
		success_ids = []
		failure_ids = []
		json_list.each do |json|
			code = json['code']
			details = json['details']
			id = details['id']
			if code == "SUCCESS" then
				success_ids[success_ids.length] = id
			else
				failure_ids[failure_ids.length] = id
			end
		end
		if failure_ids.length > 0 then
			print "There are #{failure_ids.length} failures :::: "
			return false, failure_ids
		else
			return true, failure_ids
		end
	end

	def get_notes
		if @module_obj.nil? then
			print "Please set the module_obj for the record and proceed."
			return false, {}
		end
		# Url : https://www.zohoapis.com/crm/v2/{Module}/{record_id}/Notes
		return_hash = {}
		notes_mod_obj = @module_obj.load_crm_module('Notes')
		url = Constants::DEF_CRMAPI_URL + @module_name + URL_PATH_SEPERATOR + self.record_id + URL_PATH_SEPERATOR + "Notes"
		zclient = @module_obj.get_zclient
		headers = zclient.construct_headers
		params = {}
		response = zclient._get(url,params, headers)
		body = response.body
		notes_list = Api_Methods._get_list(body, "data")
		notes_list.each do |json|
			note_obj = ZCRMRecord.new(notes_mod_obj.api_name, json, notes_mod_obj.get_fields, notes_mod_obj)
			note_id = note_obj.record_id
			return_hash[note_id] = note_obj
		end
		return true, return_hash
	end

	def delink_rl(rel_api_name, rel_id) 
		# The document says: 
		# Module supported are 1) Campaigns 2) Products
		is_supported_module = false		
		if (rel_api_name == "Campaigns" || rel_api_name == "Products") then
			is_supported_module = true
		end
		if !is_supported_module then
			print "Please check the module name, we only support Campaigns and Products."
			return false
		end
		url = Constants::DEF_CRMAPI_URL + @module_name + URL_PATH_SEPERATOR + @record_id + URL_PATH_SEPERATOR + rel_api_name + rel_id
		zclient = @module_obj.get_zclient
		headers = zclient.construct_headers
		params = {}
		response = zclient._delete(url, params, headers)
		result = is_delink_success(response)
		return result
	end

	def is_delink_success(response, rel_id)
		# Get a successful delink response 
		# Delink is not working, will have to talk to raghu :) 
		body = response.body
		list = Api_Methods._get_list(body, "data")
		list.each do |json|
			code = json['code']
			if code == "SUCCESS" then
				return true
			end
		end
		return false
	end

	def get_related_records(rel_api_name)
		if @module_obj.nil? then
			print "Please set ZCRMModule object for this ZCRMRecord object and then try. Thanks!"
			return false, {}
		end
		rel_obj = get_related_list_obj(rel_api_name)
		return_hash = {}
		rel_module_name = rel_obj.module_name
		rel_api_name = rel_obj.api_name
		is_rel_module = rel_obj.is_module

		mod_api_obj = nil
		if is_rel_module then
			mod_api_obj = @module_obj.load_crm_module(rel_module_name)
		end

		url = Constants::DEF_CRMAPI_URL + URL_PATH_SEPERATOR + @module_obj.module_name + URL_PATH_SEPERATOR + @record_id + URL_PATH_SEPERATOR + rel_obj.api_name
		headers = @zclient.construct_headers
		params = {}
		response = @zclient._get(url, params, headers)
		body = response.body
		records_json = Api_Methods._get_list(body, "data")
		records_json.each do |record|
			record_obj = nil
			if is_rel_module then
				record_obj = ZCRMRecord.new(rel_module_name, hash_values, mod_api_obj.get_fields, mod_api_obj)
				id = record_obj.record_id
			else
				record_obj = ZCRMRecord.new(rel_api_name, hash_values, nil, nil)
				id = record_obj.record_id
			end
			return_hash[id] = record_obj
		end
		return true, return_hash
	end

	def get_related_list_obj(rel_api_name)
		return_rel_obj = nil
		if @module_obj.nil? then
			print "Please set module obj"
			return false,return_rel_obj
		end
		rel_hash = @module_obj.related_list_hash
		rel_hash.each do |rel|
			api_name = rel['api_name']
			if api_name == rel_api_name then
				return_rel_obj = RelatedList.new(rel)
				return return_rel_obj
			end
		end
	end

	def get_module_obj
		return @module_obj
	end

	def set_module_obj(mod_obj)
		@module_obj = mod_obj
	end

	def get_required_fields
		if !@required_fields.empty? then
			return @required_fields
		else
			@fields.each do |id, f|
				if f.is_required then
					field_name = f.field_name
					@required_fields[@required_fields.length] = field_name
				end
			end
		end
	end

	def get(key)
		return @hash_values[key]
	end

	def set(key, value)
		field = @fields[key]
		data_type = ""
		if field.nil? then
			length = @unavailable_fields.length
			@unavailable_fields[length] = key
		elsif
			data_type = field.get_datatype
		end
		current_value = get(key)
		if current_value.nil? then
			@added_fields[key] = current_value
			@hash_values[key] = value
			return true
		else
			return update(key,value,current_value, data_type)
		end
	end

	def update(key, value, current_value="", data_type="")
		#The function returns two values, 
		#1) boolean - to say if the new value is over-written successfully
		#2) message - Result of the function in words
		message = "Value updated locally"

		if current_value.empty? then
			current_value = get(key)
		end
		if current_value.nil? then
			message = "Field cannot be found, try 'set' method to add a new key."
			return false, message
		elsif current_value.class != value.class then
			message = "Datatype mismatch, with current_value of the field. Please check the given value." 
			if !data_type.empty? 
				message = message+" Further info: field is of datatype "+data_type
			end
			return false, message
		else
			@modified_fields[key] = current_value
			@hash_values[key] = value
			return true, message
		end
	end

	#Getters and setters :: Named in a fashion easier to understand for api users
	def delete
		is_record_marked_for_deletion = true
	end
	def undo_delete
		is_record_marked_for_deletion = false
	end

	def construct_upsert_hash
		if @module_obj.nil? then
			ZohoCRMClient.log("Please set module_obj for the record to continue")
			return false, nil
		end

		req_field_ids = @module_obj.get_required_fields
		all_fields = @module_obj.get_fields
		required_fields_available = true
		err_field_ids = []
		req_field_ids.each do |f_id|
			f_obj = all_fields[f_id]
			f_name = f_obj.field_name
			val = get(f_name)
			if val.nil? then
				required_fields_available = false
				err_field_ids[err_field_ids.length] = f_id
				ZohoCRMClient.debug_log("this field name has nil value : #{f_name}")
			end
		end

		if !required_fields_available then
			ZohoCRMClient.log("Values missing for following required fields, #{err_field_ids.inspect}")
			return false, err_field_ids
		end
		update_hash = {}
		if !self.record_id.nil? then
			update_hash['id'] = self.record_id
			print "After adding id jsonkey ::: ", "\n"
		end

		@added_fields.each do |field_name, current_value| 
			update_hash[field_name] = get(field_name)
		end
		@modified_fields.each do |field_name, current_value|
			update_hash[field_name] = get(field_name)
		end
		return true, update_hash
	end

	#Utility function below
	def construct_update_hash #Contains a lot of print statements: Please remove when the function is working properly
		print 'Inside construct_update_hash :::: ', "\n"
		#Check for id presence when you are writing this function
		#If there's no id then you just have to no include it in the final update_hash
		update_hash = {}

		#update_hash['data'] = update_hash
		if !self.record_id.nil? then
			update_hash['id'] = self.record_id
			print "After adding id jsonkey ::: ", "\n"
		end

		print "Added fields ====> ", "\n"
		print @added_fields, "\n"
		print @modified_fields, "\n"

		@added_fields.each do |field_name, current_value| 
			update_hash[field_name] = get(field_name)
		end
		@modified_fields.each do |field_name, current_value|
			update_hash[field_name] = get(field_name)
		end

		print "Printing final update hash ====> ", "\n"
		print update_hash
		print "\n"
		return update_hash
	end

	def record_errors(record_obj)
		temp_list = record_obj.keys
		@error_fields_lastupdate = @fields_sent_lastupdate - temp_list
		@update_cycle_complete = true
	end
	def get_errorfields_lastupdate
		if @update_cycle_complete then
			return @error_fields_lastupdate
		end
	end
	def check_fields
		res = false
		if @hash_values.empty? then
			return false
		else
			fieldlist = self.get_field_list
			returned_fieldlist = @hash_values.keys
			l1 = fieldlist.length
			l2 = returned_fieldlist.length
			if l2 > l1
				res = true 
			else
				res = false
			end
		end
		return res
	end

	def get_field_list
		res = []
		@fields.each do |field_id, field_obj|
			res[res.length] = field_obj.field_name
		end
		return res
	end
	def module_name
		return @module_name
	end
	def record_id
		return @record_id
	end
	private :update
end