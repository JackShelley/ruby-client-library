require "ZohoCRM_Client"

RSpec.describe Api_Methods do
	def check_module_metadata(module_list, location)
		f_mods = []
		module_list.each do |mod, mod_obj|
			file = @module_metadata_filename + "_" +  mod
			fp = location + file
			if File.exist? fp then
				obj = Meta_data::load_yaml(fp)
				assert2 = obj.class.public_instance_methods.include? :get_records
				if !assert2 then
					f_mods[f_mods.length] = mod
				end
			else
				f_mods[f_mods.length] = mod
			end
		end
		if f_mods.length > 0 then
			return false, f_mods
		else
			return true, []
		end
	end
	def load_modulelist_from_db(fp=@module_list_file)
		return Meta_data::load_yaml(fp)
	end
	def save_modulelist_from_db(obj, fp=@module_list_file)
		Meta_data::dump_yaml(obj, fp)
	end

	before do
		@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.6bef93dda6e4e4b80d708f7ea6b36427.a63ab9142f997d5178f15899df2ecd59", "1000.8db09091600ec20096f8621275ac0f32.4ddc3a71c96c6dd2eca35a568caba984", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@invalid_location = "/this/location/does/not/exist"
		@valid_location = "/Users/kamalkumar/spec_meta_folder/"
		@apiObj = Api_Methods.new(@zclient, @valid_location)
		@dummy_filename = "dummy.txt"
		@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9adfebe56ae6bb8", "1000.7461b182dfddc8e94bf1d9d770fdb.73dc7bb4ae2445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@module_metadata_filename = "/module_data"
		@user_metadata_filename = "/user_data"
		@org_metadata_filename = "/org_data"
		@module_list = Meta_data.get_module_list(@zclient, true)
		@new_folder_cnt = 0
		@unused_location = "/Users/kamalkumar/spec_meta_folder/unused/"
		@module_list_file = "/Users/kamalkumar/spec_meta_folder/module_list"
		save_modulelist_from_db(@module_list, @module_list_file)
		@modules_map = load_modulelist_from_db(@module_list_file)
		#@apiObj.refresh_metadata

	end
=begin
tonite's task. 
	Why does not initialize return nil, instead it always returns an object of ApiMethods
	describe ".initialize" do
		context "zclient is nil " do
			it "should return nil " do
				api = Api_Methods.new(nil, @valid_location)
				ZohoCRMClient.debug_log("The returned api =====> #{api}")
				ZohoCRMClient.debug_log("printing apiObj zclient ====> #{api.zclient.nil?}")
				ZohoCRMClient.debug_log("Printing apiObj meta_folder ====> #{api.meta_folder.nil?}")
				ZohoCRMClient.debug_log("#{api.empty?}")
				#expect(api).to be_nil
			end
		end
		context "meta_folder is not a valid location" do
			it "should return nil" do
				api = Api_Methods.new(@zclient, @invalid_location)
				expect(api).to be_nil
			end
		end
		context "zclient credentials are wrong " do
			it "should return nil, in case of tokens being invalid " do
				result = @improper_zclient.revoke_token
				expect(result).to be_eq false
				api = Api_Methods.new(@improper_zclient, @valid_location)
				expect(api).to be_nil
			end
			it "upon an api call, we should be able to mark zclient as invalid" do
				#Please read!
				#if there is an auth error in the api, revoke token will be called
				#revoke token can mark if a token is bad.
				expect(false).to be_eq true
			end
		end
	end #initialize 
=end
	describe ".refresh_metadata" do
		context "meta_folder is empty" do
			it "should create a file for every module, a file for user data, and a file for org_data" do
				api = Api_Methods.new(@zclient, @valid_location)
				api.refresh_metadata
				module_list = load_modulelist_from_db.keys
				module_list.each do |module_name|
					file_name = @module_metadata_filename + "_" + module_name
					fp = @valid_location + file_name
					assert1 = File.exist?(fp)
					expect(assert1).to eq(true)
					obj = Meta_data::load_yaml(fp)
					assert2 = obj.class.public_instance_methods.include? :get_records
					expect(assert2).to eq(true)
				end
				userfp = @valid_location + @user_metadata_filename
				expect(File.exist?(userfp)).to eq(true)
				users = Meta_data::load_yaml(userfp)
				expect(users).not_to be_nil
				orgfp = @valid_location + @org_metadata_filename
				expect(File.exist?(orgfp)).to eq(true)
				org = Meta_data::load_yaml(orgfp)
				expect(org).not_to be_nil
			end
		end
		context "meta_data available already" do
			it "should overwrite the files" do
				api = Api_Methods.new(@zclient, @valid_location)
				leads_file = @module_metadata_filename + "_Leads"
				leads_fp = @valid_location + leads_file
				if !File.exist?(leads_fp) then
					api.refresh_metadata
				end
				api.refresh_metadata
				module_list = load_modulelist_from_db.keys
				module_list.each do |module_name|
					file_name = @module_metadata_filename + "_" + module_name
					fp = @valid_location + file_name
					assert1 = File.exist?(fp)
					expect(assert1).to eq(true)
					obj = Meta_data::load_yaml(fp)
					assert2 = obj.class.public_instance_methods.include? :get_records
					expect(assert2).to eq(true)
				end
				userfp = @valid_location + @user_metadata_filename
				expect(File.exist?(userfp)).to eq(true)
				users = Meta_data::load_yaml(userfp)
				expect(users).not_to be_nil
				orgfp = @valid_location + @org_metadata_filename
				expect(File.exist?(orgfp)).to eq(true)
				org = Meta_data::load_yaml(orgfp)
				expect(org).not_to be_nil
			end
		end
	end #describe .refresh_metadata

	describe ".refresh_module_data" do
		context "modules is empty" do
			it "returns false and an empty array" do
				location = @valid_location + "modules_test/"
				api = Api_Methods.new(@zclient, location)
				expect(api.zclient).not_to be_nil
				expect(api.meta_folder).not_to be_nil
				res, f_mods = api.refresh_module_data(nil)
				expect(res).to eq false
				expect(f_mods).to be_empty
				res, f_mods = api.refresh_module_data
				expect(res).to eq false
				expect(f_mods).to be_empty
			end
		end
		context "Improper module names passed" do
			it "returns false, array of module_names that failed" do
				improper_modules = Array.new(["module_doesnt_exist1","module_doesnt_exist2","module_doesnt_exist3","module_doesnt_exist4","module_doesnt_exist5"])
				#ZohoCRMClient.debug_log("Printing improper_modules array ===> #{improper_modules}")
				location = @valid_location + "modules_test/"
				api = Api_Methods.new(@zclient, location)
				list = @module_list.keys + improper_modules
				res, f_mods = api.refresh_module_data(list)
				#ZohoCRMClient.debug_log("Printing result for the refresh_metadata ===> #{res}")
				#ZohoCRMClient.debug_log("Print returned failed modules ===> #{f_mods}")
				expect(res).to eq false
				assert1 = ((improper_modules - f_mods) == (f_mods - improper_modules)) && (improper_modules.length == f_mods.length)
				#ZohoCRMClient.debug_log("Printing assert1 ===> #{assert1}")
				#ZohoCRMClient.debug_log("#{(improper_modules - f_mods) == (f_mods - improper_modules)}")

				expect(assert1).to eq true
				res, f_mods = check_module_metadata(@module_list, location)
				expect(res).to eq true
				expect(f_mods).to be_empty
			end
		end
		context "zclient is not valid" do
			it "returns false, []" do
				apiObj = Api_Methods.new(@improper_zclient, @valid_location)
				res, f_mods = apiObj.refresh_module_data(@module_list)
				expect(res).to eq false
				expect(f_mods).to be_empty
			end
		end
	end #describe .refresh_module_data

	describe ".load_crm_module" do
		context "module name invalid " do
			it "should return nil" do
				mod_name = "module_doesnt_exist"
				res = @apiObj.load_crm_module(mod_name)
				expect(res).to be_nil
			end
		end
		context "module_name is nil " do
			it "should return nil" do
				mod_name = nil
				res = @apiObj.load_crm_module(nil)
				expect(res).to be_nil
			end
		end
		context "module_name is empty " do
			it "should return nil" do
				res = @apiObj.load_crm_module("")
				expect(res).to be_nil
			end
		end
		context "when the collect meta_data has not been called" do
			it "should return nil" do
				dir_path = @unused_location
				_api = Api_Methods.new(@zclient, @unused_location)
				mod_name = "Leads"
				res = _api.load_crm_module(mod_name)
				expect(res).to be_nil
			end
		end
		context "valid function call" do
			it "should return ZCRMModule object" do
				#@apiObj.refresh_metadata
				list = @module_list.keys
				list.each do |mod|
					res = @apiObj.load_crm_module(mod)
					expect(res).not_to be_nil
					assert = res.class.public_instance_methods.include? :get_records
					expect(res).to be_instance_of(ZCRMModule)
					expect(assert).to eq true
				end
			end
		end
	end #describe .load_crm_module

	describe "load_user_data" do
		context "called before collecting meta_data" do
			it "should return nil" do
				_api = Api_Methods.new(@zclient, @unused_location)
				userObj = _api.load_user_data
				expect(userObj).to be_nil
			end
		end
		context "a valid call" do
			it "should return a hash map of users" do
				userObj = @apiObj.load_user_data
				expect(userObj).not_to be_nil
				expect(userObj).not_to be_empty
				userObj.each do |id, user|
					expect(id).not_to be_nil
					expect(id).not_to be_empty
					expect(user).not_to be_nil
					expect(user).not_to be_empty
				end
			end
		end
	end #describe .load_user_data

	describe "load_org_data" do
		context "called before collecting meta_data" do
			it "should return nil" do
				_api = Api_Methods.new(@zclient, @unused_location)
				orgObj = _api.load_org_data
				expect(orgObj).to be_nil
			end
		end
		context "a valid call", :focus => true do
			it "should return a hash map of users" do
				orgObj = @apiObj.load_org_data
				expect(orgObj).not_to be_nil
				expect(orgObj).not_to be_empty
			end
		end
	end #describe load_org_data


end #describe Api_Methods
