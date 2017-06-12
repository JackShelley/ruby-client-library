require 'json'

$default_api_url = 'https://www.zohoapis.com/crm/v2/'
$def_api_domain = 'zohoapis.com'
$def_api_path = '/crm/v2/'


# Current directory : Dir.pwd
# Current file : __FILE__
# Current line no : __LINE__

module Meta_data

	module_metadata_filename = "module_data"

	def module_data(zclient, refresh = true, meta_folder="../meta_data")      ## We do not want to put switch case, because having each functionality as a diff function is easier for the user 
		## Mainly required properties : module_name, api_name, display_name, singular_name, plural_name
		begin
			headers = zclient.construct_headers
			module_url_path = "settings/modules"
			module_url = Constants::DEF_ACCOUNTS_URL+module_url_path
			print "url ::: ", module_url, "\n"
			response = zclient._get(module_url, {}, headers)
			body = response.body
			json_list = Api_Methods._get_list(body, "modules")
			path = File.dirname(__FILE__) + meta_folder
			file_name = "/module_data"
			module_obj = {}
			json_list.each do |obj|
				key = obj['api_name']
				module_obj[key] = obj
			end
			begin
				Meta_data::dump_yaml(module_obj, path+file_name)
			rescue
				panic "Error occurred while dumping module meta_data "+path+file_name
			end
		rescue
			panic "Error in collecting module_data method ::: "
		end
	end

	def load_module_data(meta_folder="../meta_data")
		begin
			file = File.directory(__FILE__) + meta_folder + module_metadata_filename
			res = Meta_data::load_yaml(file)
		rescue
			panic "Error occurred loading module_data from its meta_data file ::: Please check the files "
		end
		return res
	end

	def users_data(zclient, refresh = true, meta_folder="../meta_data")
		## user_id, user_name, user_email, created_time (invitation_accepted_time)

	end

	def org_data(zclient, refresh = true, meta_folder="../meta_data")
		## org_name, zgid
	end

	def collect_metadata(zclient, refresh = true, meta_folder="../meta_data")
		mod_res = module_data(zclient, refresh, meta_folder)
		if mod_res then
			puts "pulling module_data was successful ::: "
		else
			panic "Problem while getting meta_data ::: module_data"
		end

		# Add more as needed
	end

	# YAML related functions ::: For Serializing and De-Serializing objects 
	# they both Throw File opening related exceptions
	# | Dumps serializable content into a given file |
	def dump_yaml(obj, file)
	    ser_obj = YAML::dump(obj)
	    f = File.open(file, 'w')
	    f.puts = ser_obj
	end

	# | Loads the serialized content in the given file as an object, which will be returned |
	def load_yaml(file) 
		content = ""
		File.open(file, 'r').do |f|
			while line=f.gets do
		  		content = content + line
			end
		end
		obj = YAML::load(content)
		return obj
	end


end

class Api_Methods
	include meta_data
	attr_accessor :zclient, :meta_data_folder
	def initialize(zclient, meta_data_folder="../meta_data")
		@zclient, @meta_folder = zclient, meta_data_folder
		if @meta_folder == "../meta_data" then
			@is_def_mfolder = true
		else
			@is_def_mfolder = false
		end
	end

	def refresh_metadata(refresh = true)
		if self.is_def_mfolder then
			Meta_data::collect_metadata(@zclient, refresh)
		else
			Meta_data::collect_metadata(@zclient, refresh, meta_folder)
		end
	end

	def self._get_list(resp_json, key) #Internal use
		begin
			json = JSON.parse(resp_json)
			res = json[key]
		rescue
			puts "From Api_Methods :::: _get_list: " << "\n"
			panic "Exception while parsing response body ::: "
		end
		return res
	end
end