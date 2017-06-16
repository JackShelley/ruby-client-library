require 'json'
require 'yaml'

$default_api_url = 'https://www.zohoapis.com/crm/v2/'
$def_api_domain = 'zohoapis.com'
$def_api_path = '/crm/v2/'


# Current directory : Dir.pwd
# Current file : __FILE__
# Current line no : __LINE__

class Meta_data

	@@module_metadata_filename = "/module_data"
	@@user_metadata_filename = "/user_data"
	@@org_metadata_filename = "/org_data"

	def self.module_data(zclient, module_name, meta_folder="/Users/kamalkumar/Desktop/")
		## Mainly required properties : module_name, api_name, display_name, singular_name, plural_name
		#DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
		#Actual = "https://www.zohoapis.com/crm/v2/settings/modules/{module_name}"
		begin
			headers = zclient.construct_headers
			module_url_path = "settings/modules/"
			module_url = Constants::DEF_CRMAPI_URL + module_url_path + module_url_path
			print "url ::: ", module_url
			response = zclient._get(module_url, {}, headers)
			body = response.body
			json_list = Api_Methods._get_list(body, "modules")
			json = json_list[0]
			path = meta_folder
			file_name = @@module_metadata_filename + '_' + module_name
			api_name = json['api_name']
			singular_label = json['singular_label']
			plural_label = json['plural_label']
			mod_obj = ZCRMModule.new(zclient, api_name, singular_label, plural_label, json, meta_folder)
			field_list = json['fields']
			field_list.each do |field|
				api_name = field['api_name']
				field_label = field['field_label']
				json_type = field['json_type']
				data_type = field['data_type']
				custom_field = field['custom_field']
				if data_type == 'picklist' || data_type = 'multiselectpicklist'
					is_picklist = true
				else
					is_picklist = false
				end
				f = ZCRMField.new(api_name, field_label, json_type, data_type, custom_field, is_picklist, field)
				mod_obj.add_field(f)
			end
			Meta_data::dump_yaml(module_obj, path+file_name)
			res = true
		rescue Exception => e
			handle_exception(e, "Exception occurred while fetching whole module data for "+module_name)
			res = false
		end
		return res
	end

	def self.load_crm_module(module_name, meta_folder)
		file_name = @module_metadata_filename+module_name
		file = meta_folder+file_name
		result_obj = Meta_data.load_yaml(file)
		return result_obj
	end

	def get_module_list(api_supported = true)
		# Actual url: https://www.zohoapis.com/crm/v2/settings/modules
		# DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
		res = {}
		url_path = "settings/modules"
		url = Constants::DEF_CRMAPI_URL + url_path
		headers = zclient.construct_headers
		response = zclient._get(url, {}, headers)
		body = response.body 
		module_list = Api_Methods._get_list(body)
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
	def get_allmodule_data(zclient, meta_folder) 
		failed_modules = []
		module_list = get_module_list
		module_list.each do |module_name|
			if !module_data(zclient, module_name, meta_folder) then
				failed_modules[failed_modules.length] = module_name
			end
		end
		if failed_modules.empty? then
			return true, failed_modules
		else
			return false, failed_modules
	end

	def self.user_data(zclient, refresh = true, meta_folder="/Users/kamalkumar/Desktop/")
		## user_id, user_name, user_email, created_time (invitation_accepted_time)
		#DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
		#Actual = "https://www.zohoapis.com/crm/v2/users"
		begin
			headers = zclient.construct_headers
			path = "users"
			url = Constants::DEF_CRMAPI_URL + path
			print "url ::: ", url, "\n"
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
				ZohoCRMClient.panic "Error occurred while dumping module meta_data "+path+file_name
			end

		rescue Exception => e
			res = false
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.panic "Error in collecting users_data method ::: "
		end
	end

	def self.load_user_data(meta_folder="/Users/kamalkumar/Desktop/")
		begin
			file = meta_folder + @@user_metadata_filename
			res = Meta_data::load_yaml(file)
		rescue
			ZohoCRMClient.panic "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

	def self.org_data(zclient, refresh = true, meta_folder="/Users/kamalkumar/Desktop/")
		## org_name, zgid
		#DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
		#Actual = "https://www.zohoapis.com/crm/v2/org"
		begin
			headers = zclient.construct_headers
			path = "org"
			url = Constants::DEF_CRMAPI_URL + path
			print "url ::: ", url, "\n"
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
				ZohoCRMClient.panic "Error occurred while dumping org meta_data "+path+file_name
			end

		rescue Exception => e
			res = false
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.panic "Error in collecting org_data method ::: "
		end
	end

	def self.load_org_data(meta_folder="/Users/kamalkumar/Desktop/")
		begin
			file = meta_folder + @@org_metadata_filename
			res = Meta_data::load_yaml(file)
		rescue Exception => e
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.panic "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

	def self.collect_metadata(zclient, meta_folder="/Users/kamalkumar/Desktop/")
		mod_res,failed_modules = get_allmodule_data(zclient, meta_folder)
		if mod_res then
			puts "pulling module_data was successful ::: " << "\n"
		else
			puts "Problem while getting module data" << "\n"
			puts "Fetching data failed for the following modules :: " << "\n"
			puts failed_modules
		end
		user_res = user_data(zclient, refresh, meta_folder)
		if user_res then
			puts "pulling module_data was successful ::: " << "\n"
		else
			puts "Problem while getting module data" << "\n"
		end
		org_res = org_data(zclient, refresh, meta_folder)
		if org_res then
			puts "pulling module_data was successful ::: " << "\n"
		else
			puts "Problem while getting module data" << "\n"
		end
	end

	# YAML related functions ::: For Serializing and De-Serializing objects 
	# they both Throw File opening related exceptions
	# | Dumps serializable content into a given file |
	def self.dump_yaml(obj, file)
		puts file
		print "\n"
		print obj
	    ser_obj = YAML::dump(obj)
	    f = File.new(file, 'w')
	    f.puts ser_obj
	    f.close
	end

	def self.load_yaml(file) 
		content = ""
		f = File.open(file, 'r')
		while line=f.gets do
	  		content = content + line
		end
		obj = YAML::load(content)
		return obj
	end

	def self.old_module_data(zclient, meta_folder="/Users/kamalkumar/Desktop/")
		## Mainly required properties : module_name, api_name, display_name, singular_name, plural_name
		#DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
		#Actual = "https://www.zohoapis.com/crm/v2/settings/modules"
		res = true
		begin
			headers = zclient.construct_headers
			module_url_path = "settings/modules"
			module_url = Constants::DEF_CRMAPI_URL+module_url_path
			print "url ::: ", module_url, "\n"
			response = zclient._get(module_url, {}, headers)
			body = response.body
			json_list = Api_Methods._get_list(body, "modules")
			path = meta_folder
			file_name = @@module_metadata_filename
			module_obj = {}
			json_list.each do |obj|
				key = obj['api_name']
				module_obj[key] = obj
			end
			begin
				Meta_data::dump_yaml(module_obj, path+file_name)
				res = true
			rescue Exception => e
				res = false
				puts e.message
				puts e.backtrace.inspect
				ZohoCRMClient.panic "Error occurred while dumping module meta_data "+path+file_name
			end
		rescue Exception => e
			res = false
			puts e.message
			puts e.backtrace.inspect
			ZohoCRMClient.panic "Error in collecting module_data method ::: "
		end
		return res
	end

	def self.old_load_module_data(meta_folder="/Users/kamalkumar/Desktop/")
		begin
			file = meta_folder + @@module_metadata_filename
			res = Meta_data::load_yaml(file)
		rescue
			ZohoCRMClient.panic "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

end


class Api_Methods
	attr_accessor :zclient, :meta_data_folder
	def initialize(zclient, meta_data_folder="/Users/kamalkumar/Desktop/")
		@zclient, @meta_folder = zclient, meta_data_folder
	end
	def refresh_metadata
		Meta_data.collect_metadata(@zclient, @meta_folder)
	end
	def refresh_module_data(modules=[])
		modules.each do |module_name|
			Meta_data::module_data(zclient, module_name, @meta_folder)
		end
	end
	def load_crm_module(module_name)
		return Meta_data::load_crm_module(module_name)
	end

	#Utility_functions
	def self._get_list(resp_json, key) #Internal use
		begin
			json = JSON.parse(resp_json)
			res = json[key]
		rescue
			puts "From Api_Methods :::: _get_list: " << "\n"
			ZohoCRMClient.panic "Exception while parsing response body ::: "
		end
		return res
	end


end