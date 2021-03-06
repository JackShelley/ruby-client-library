require 'json'
require 'yaml'

$default_api_url = 'https://www.zohoapis.com/crm/v2/'
$def_api_domain = 'zohoapis.com'
$def_api_path = '/crm/v2/'

class Meta_data

	@@module_metadata_filename = "/module_data"
	@@user_metadata_filename = "/user_data"
	@@org_metadata_filename = "/org_data"

	def self.module_data(zclient, module_name, meta_folder)
		if zclient.nil? then
			return false
		end
		if module_name.nil? || module_name.empty? then
			return false
		end
		begin
			headers = zclient.construct_headers
			module_url_path = "settings/modules/"
			#module_url = Constants::DEF_CRMAPI_URL + module_url_path + module_name
			module_url = Constants::ZOHOAPIS_URL + zclient.get_domain + Constants::V2_PATH + module_url_path + module_name
			response = zclient.safe_get(module_url, {}, headers)
			if response.nil? then
				ZohoCRMClient.debug_log("Response is nil for module ===> #{module_name}")
				return false
			end
			body = response.body
			json_list = Api_Methods._get_list(body, "modules")
			json = json_list[0]
			path = meta_folder
			file_name = @@module_metadata_filename + '_' + module_name
			api_name = json['api_name']
			singular_label = json['singular_label']
			plural_label = json['plural_label']
			mod_obj = ZCRMModule.new(zclient, json, meta_folder, api_name, singular_label, plural_label)
			layouts = json["layouts"]
			layout_objs = []
			layouts.each do |layout_hash|
				layout_obj = ZCRMLayout.new(layout_hash)
				layout_objs[layout_objs.length] = layout_obj
			end
			mod_obj.set_layouts(layout_objs)

			field_list = json['fields']
			field_list.each do |field|
				api_name = field['api_name']
				field_label = field['field_label']
				json_type = field['json_type']
				data_type = field['data_type']
				custom_field = field['custom_field']
				if data_type == 'picklist' || data_type == 'multiselectpicklist'
					is_picklist = true
				else
					is_picklist = false
				end
				f = ZCRMField.new(api_name, field_label, json_type, data_type, custom_field, is_picklist, field)
				if is_picklist then
					picklist_values = field['pick_list_values']
					f.set_picklist_values(picklist_values)
				end
				res = mod_obj.add_field(f)
				if !res then
					ZohoCRMClient.debug_log("Something wrong is trying to get in fields array " + f)
				end
			end
			req_fields = mod_obj.get_required_fields #This line is trivial, doesn't hurt.
			Meta_data::dump_yaml(mod_obj, path+file_name)
			res = true
		rescue Exception => e
			ZohoCRMClient.debug_log("Exception occurred while fetching module data for ==> #{module_name}")
			ZohoCRMClient.debug_log(e.messsage)
			ZohoCRMClient.debug_log(e.backtrace.inspect)
			res = false
		end
		return res
	end

	def self.load_crm_module(module_name, meta_folder)
		file_name = @@module_metadata_filename + '_' + module_name
		if module_name.nil? || meta_folder.nil? then
			return nil
		end
		if module_name.empty? || meta_folder.empty? then
			return nil
		end
		file = meta_folder + file_name
		result_obj = Meta_data.load_yaml(file)
		return result_obj
	end

	def self.get_module_names(zclient, api_supported=true)
		res = Meta_data.get_module_list(zclient, api_supported)
		return res.keys
	end

	def self.get_module_list(zclient, api_supported = true)
		res = {}
		url_path = "settings/modules"
		#url = Constants::DEF_CRMAPI_URL + url_path
		url = Constants::ZOHOAPIS_URL + zclient.get_domain + Constants::V2_PATH + url_path
		headers = zclient.construct_headers
		response = zclient._get(url, {}, headers)
		body = response.body 
		module_list = Api_Methods._get_list(body, 'modules')
		module_list.each do |obj|
			module_name = obj['api_name']
			has_api = obj['api_supported']
			if api_supported then
				if has_api then
					res[module_name] = obj
				end
			else
				res[module_name] = obj
			end
		end
		return res
	end

	#Returns two objects,
	# 1) Boolean - denotes if collecting all the data was successful
	# 2) Array - Modules that failed because of some error
	def self.get_allmodule_data(zclient, meta_folder) 
		failed_modules = []
		module_list = get_module_list(zclient)
		module_list.each do |module_name, module_obj|
			if !module_data(zclient, module_name, meta_folder) then
				failed_modules[failed_modules.length] = module_name
			end
		end
		if failed_modules.empty? then
			return true, failed_modules
		else
			return false, failed_modules
		end
	end

	def self.user_data(zclient, refresh = true, meta_folder="/Users/kamalkumar/Desktop/")
		res = false
		begin
			headers = zclient.construct_headers
			path = "users"
			#url = Constants::DEF_CRMAPI_URL + path
			url = Constants::ZOHOAPIS_URL + zclient.get_domain + Constants::V2_PATH + path
			response = zclient._get(url, {}, headers)
			body = response.body
			json_list = Api_Methods._get_list(body, "users")

			path = meta_folder
			file_name = @@user_metadata_filename
			users_obj = {}
			json_list.each do |obj|
				key = obj['id']
				users_obj[key] = obj
			end
			begin
				Meta_data::dump_yaml(users_obj, path+file_name)
				res = true
			rescue Exception => e
				res = false
				puts e.message
				puts e.backtrace.inspect
				ZohoCRMClient.debug_log "Error occurred while dumping module meta_data "+path+file_name
			end

		rescue Exception => e
			res = false
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.panic "Error in collecting users_data method ::: "
		end
		return res
	end

	def self.load_user_data(meta_folder="/Users/kamalkumar/Desktop/")
		res = nil
		begin
			file = meta_folder + @@user_metadata_filename
			if File.exists?(file) then
				res = Meta_data::load_yaml(file)
			else
				ZohoCRMClient.debug_log("File did not : #{file}")
				return nil
			end
		rescue
			ZohoCRMClient.debug_log "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

	def self.org_data(zclient, refresh = true, meta_folder="/Users/kamalkumar/Desktop/")
		res = false
		begin
			headers = zclient.construct_headers
			path = "org"
			#url = Constants::DEF_CRMAPI_URL + path
			url = Constants::ZOHOAPIS_URL + zclient.get_domain + Constants::V2_PATH + path
			response = zclient._get(url, {}, headers)
			body = response.body
			json_list = Api_Methods._get_list(body, "org")

			path = meta_folder
			file_name = @@org_metadata_filename
			org_obj = {}
			json_list.each do |obj|
				key = obj['id']
				org_obj[key] = obj
			end
			begin
				Meta_data::dump_yaml(org_obj, path+file_name)
				res = true
			rescue Exception => e
				res = false
				puts e.message
				puts e.backtrace.inspect
				ZohoCRMClient.debug_log "Error occurred while dumping org meta_data "+path+file_name
			end

		rescue Exception => e
			res = false
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.debug_log "Error in collecting org_data method ::: "
		end
		return res
	end

	def self.load_org_data(meta_folder="/Users/kamalkumar/Desktop/")
		res = nil
		begin
			file = meta_folder + @@org_metadata_filename
			if File.exists?(file) then
				res = Meta_data::load_yaml(file)
			else
				ZohoCRMClient.debug_log("File did not exist : #{file}")
				return nil
			end
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.debug_log "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

	def self.collect_metadata(zclient, meta_folder="/Users/kamalkumar/Desktop/")
		mod_res,failed_modules = get_allmodule_data(zclient, meta_folder)
		refresh = true #TODO: 'refresh' parameter is not needed. Remove when you are sure that it's not needed.
		user_res = user_data(zclient, refresh, meta_folder)
		org_res = org_data(zclient, refresh, meta_folder)
	end

	# YAML functions ::: For Serializing and De-Serializing objects 
	# they both Throw File opening related exceptions
	# | Dumps serializable content into a given file |
	def self.dump_yaml(obj, file)
	    ser_obj = YAML::dump(obj)
	    f = File.new(file, 'w')
	    f.puts ser_obj
	    f.close
	end

	def self.load_yaml(file) 
		begin
			content = ""
			f = File.open(file, 'r')
			while line=f.gets do
		  		content = content + line
			end
			obj = YAML::load(content)
			return obj
		rescue
			ZohoCRMClient.log("Exception raised while loading yaml from file : "+file)
			return nil
		end
	end
end


class Api_Methods
	attr_accessor :zclient, :meta_folder
	def initialize(zclient, meta_data_folder="/Users/kamalkumar/Desktop/")
		if zclient.nil? then
			ZohoCRMClient.log("zclient that you passed is not valid. Hence returning nil")
			return nil
		end
		tokens = zclient.get_tokens
		if !tokens.is_refreshtoken_valid.nil? && !tokens.is_refreshtoken_valid  then
			ZohoCRMClient.log("Refresh token is not valid. Hence returning nil.")
			return nil
		end
		if File.exists?(meta_data_folder) then
			@meta_folder = meta_data_folder
		else
			ZohoCRMClient.log("meta_folder passed is not a valid location. Hence returning nil")
			ZohoCRMClient.debug_log("Given meta_folder #{meta_data_folder}")
			return nil
		end
		@zclient, @meta_folder = zclient, meta_data_folder
	end
	def get_zclient
		return @zclient
	end
	def get_meta_folder
		return @meta_folder
	end
	def refresh_metadata
		Meta_data.collect_metadata(@zclient, @meta_folder)
	end
	def refresh_module_data(modules=[])
		if modules.nil? then
			return false, []
		end
		if modules.empty? then
			return false, []
		end
		res = false
		s_mods = []
		f_mods = []
		modules.each do |module_name|
			begin
				res = Meta_data::module_data(zclient, module_name, @meta_folder)
			rescue => e
				if e.class == InvalidTokensError then
					return false, []
				end
			end

			if res then
				ZohoCRMClient.debug_log("Success module :: #{module_name}")
				s_mods[s_mods.length] = module_name
			else
				ZohoCRMClient.debug_log("Failed_module :: #{module_name}")
				f_mods[f_mods.length] = module_name
			end
		end
		ZohoCRMClient.debug_log("From ZohoAPIMethod successful modules : #{s_mods}")
		ZohoCRMClient.debug_log("From ZohoAPIMethod failed modules : #{f_mods}")
		if f_mods.empty? then
			return true, []
		else
			return false, f_mods
		end
	end
	def load_crm_module(module_name)
		if module_name.nil? || module_name.empty? then
			return nil
		end
		return Meta_data::load_crm_module(module_name, @meta_folder)
	end
	def load_user_data
		return Meta_data::load_user_data(@meta_folder)
	end
	def load_org_data
		return Meta_data::load_org_data(@meta_folder)
	end

	#Utility_functions
	def self._get_list(resp_json, key) #Internal use
		begin
			json = JSON.parse(resp_json)
			res = json[key]
		rescue e
			puts "From Api_Methods :::: _get_list: " << "\n"
			ZohoCRMClient.panic "Exception while parsing response body ::: "
		end
		return res
	end
end