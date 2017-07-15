require "spec_helper"
require "ZohoCRM_Client"
require "FileUtils"

RSpec.describe Meta_data do
	before do
		@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.85ecfae23e003864aa031a9afd0e3a66.c055083eb14de56feaa430e593259ff7", "1000.cc3eba9b121e8a826123367694934cd7.64dec560baeec131bfb4d757442b043b", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@invalid_location = "/this/location/does/not/exist"
		@valid_location = "/Users/kamalkumar/spec_meta_folder/"
		@apiObj = Api_Methods.new(zclient, @valid_location)
		@dummy_filename = "dummy.txt"
		@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9adfebe56ae6bb8", "1000.7461b182dfddc8e94bf1d9d770fdb.73dc7bb4ae2445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@module_metadata_filename = "/module_data"
		@user_metadata_filename = "/user_data"
		@org_metadata_filename = "/org_data"
		@module_list = Meta_data.get_module_list(@zclient, true)
		@new_folder_cnt = 0
		@unused_location = "/Users/kamalkumar/spec_meta_folder/unused/"
		@apiObj.refresh_metadata
		@test_location = "/Users/kamalkumar/spec_meta_folder/test/"
	end

	#Tests can be written for other functions in Meta_data 
	#Low priority: Since they are utility function
	
	describe "self.module_data" do
		#def self.module_data(zclient, module_name, meta_folder)
		context "zclient is nil" do
			it "should return false" do
				zclient = nil
				module_name = "Leads"
				meta_folder = @valid_location
				res = Meta_data.module_data(zclient, module_name, meta_folder)
				expect(res).to be_eq false
			end
		end
		context "zclient is improper " do
			it "should return false " do
				module_name = "Leads"
				meta_folder = @valid_location
				res = Meta_data.module_data(@improper_zclient, module_name, meta_folder)
				expect(res).to be_eq false
			end
		end
		context "module_name is empty" do
			it "should return false" do
				module_name = ""
				meta_folder = @valid_location
				res = Meta_data.module_data(@zclient, module_name, meta_folder)
				expect(res).to be_eq false
			end
		end
		context "module_name is nil" do
			it "should return false" do
				module_name = nil
				meta_folder = @valid_location
				res = Meta_data.module_data(@zclient, module_name, meta_folder)
				expect(res).to be_eq false
			end
		end
		context "module_name is invalid" do
			it "should return false" do
				module_name = "module_doesnt_exist"
				meta_folder = @valid_location
				res = Meta_data.module_data(@zclient, module_name, meta_folder)
			end
		end
		context "meta_folder location is invalid" do
			it "should return false" do
				module_name = "Leads"
				meta_folder = @invalid_location
				res = Meta_data.module_data(@zclient, module_name, meta_folder)
				expect(res).to be_eq false
			end
		end
		context "Valid modules" do
			it "should return true and create a file and write module object" do
				FileUtils.rm_f Dir.glob("#{@test_location}/*")
				location = @test_location
				zclient = @zclient
				@module_list.each do |module_name|
					res = Meta_data.module_data(zclient, module_name, location)
					expect(res).to be_eq true
					mod_obj = Meta_data.load_crm_module(module_name, location)
					expect(mod_obj).not_to be_nil
					mod = mod_obj.module_name
					expect(mod).to be_eq(module_name)
				end
			end
		end
	end

end

RSpec.describe Api_Methods do
	def check_module_metadata(module_list, location)
		f_mods = []
		module_list.each do |mod|
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
		@apiObj.refresh_metadata

	end

	describe "load_org_data" do
		context "called before collecting meta_data" do
			it "should return nil" do
				_api = Api_methods.new(@zclient, @unused_location)
				orgObj = _api.load_org_data
				expect(orgObj).to be_nil
			end
		end
		context "a valid call" do
			it "should return a hash map of users" do
				orgObj = @apiObj.load_org_data
				expect(orgObj).not_to be_nil
				expect(orgObj).not_to be_empty
			end
		end
	end

	describe "load_user_data" do
		context "called before collecting meta_data" do
			it "should return nil" do
				_api = Api_methods.new(@zclient, @unused_location)
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
	end

	describe ".load_crm_module" do
		context "module name invalid " do
			it "should return nil" do
				mod_name = "module_doesnt_exist"
				res = apiObj.load_crm_module(mod_name)
				expect(res).to be_nil
			end
		end
		context "module_name is nil " do
			it "should return nil" do
				mod_name = nil
				res = apiObj.load_crm_module(nil)
				expect(res).to be_nil
			end
		end
		context "module_name is empty " do
			it "should return nil" do
				res = apiObj.load_crm_module("")
				expect(res).to be_nil
			end
		end
		context "when the collect meta_data has not been called" do
			it "should return nil" do
				dir_path = @unused_location
				_api = Api_Methods.new(zclient, @unused_location)
				mod_name = "Leads"
				res = _api.load_crm_module(mod_name)
				expect(res).to be_nil
			end
		end
		context "valid function call" do
			it "should return ZCRMModule object" do
				@apiObj.refresh_metadata
				@module_list.each do |mod|
					res = @apiObj.load_crm_module(mod)
					expect(res).not_to be_nil
					assert = obj.class.public_instance_methods.include? :get_records
					expect(assert).to be_eq true
				end
			end
		end
	end

	describe ".refresh_module_data" do
		let(:location) {@valid_location + "modules_test"}
		let(:api) {Api_Methods.new(@zclient, location)}
		context "modules is empty" do
			it "returns false and an empty array" do
				res, f_mods = api.refresh_module_data(nil)
				expect(res).to be_eq true
				expect(f_mods).to be_empty
				res, f_mods = api.refresh_module_data
				expect(res).to be_eq true
				expect(f_mods).to be_empty
			end
		end
		context "Improper module names passed" do
			let(:improper_modules) {Array.new("module_doesnt_exist1","module_doesnt_exist2","module_doesnt_exist3","module_doesnt_exist4","module_doesnt_exist5")}
			it "returns false, array of module_names that failed" do
				list = @module_list.concat(improper_modules)
				res, f_mods = api.refresh_module_data(list)
				expect(res).to be_eq false
				assert1 = improper_modules - f_mods == f_mods - improper_modules && improper_modules.length == f_mods.length
				expect(assert1).to be_eq true
				res, f_mods = check_module_metadata(@module_list, location)
				expect(res).to be_eq true
				expect(f_mods).to be_empty
			end
		end
		context "zclient is not valid" do
			it "returns false, []" do
				apiObj = Api_Methods.new(@improper_zclient, @valid_location)
				res, f_mods = apiObj.refresh_module_data(@module_list)
				expect(res).to be_eq false
				expect(f_mods).to be_empty
			end
		end
	end

	describe ".refresh_metadata" do
		context "meta_folder is empty" do
			it "should create a file for every module, a file for user data, and a file for org_data" do
				api = Api_Methods.new(@zclient, @valid_location)
				api.refresh_metadata
				module_list = get_module_list(@zclient, true)
				module_list.each do |module_name|
					file_name = @module_metadata_filename + "_" + module_name
					fp = @valid_location + file_name
					assert1 = File.exist?(fp)
					expect(assert1).to be_eq(true)
					obj = Meta_data::load_yaml(fp)
					assert2 = obj.class.public_instance_methods.include? :get_records
					expect(assert2).to be_eq(true)
				end
				userfp = @valid_location + @user_metadata_filename
				expect(File.exist?(userfp)).to be_eq(true)
				users = Meta_data::load_yaml(userfp)
				expect(users).not_to be_nil
				orgfp = @valid_location + @org_metadata_filename
				expect(File.exist?(orgfp)).to be_eq(true)
				org = Meta_data::load_yaml(orgfp)
				expect(org).not_to be_nil
			end
		end
		context "meta_data available already" do
			it "should overwrite the files" do
				api = Api_Methods.new(@zclient, @valid_location)
				leads_file = @module_metadata_filename + "Leads"
				leads_fp = @valid_location + leads_file
				if !File.exist?(leads_fp) then
					api.refresh_metadata
				end
				api.refresh_metadata
				module_list = get_module_list(@zclient, true)
				module_list.each do |module_name|
					file_name = @module_metadata_filename + "_" + module_name
					fp = @valid_location + file_name
					assert1 = File.exist?(fp)
					expect(assert1).to be_eq(true)
					obj = Meta_data::load_yaml(fp)
					assert2 = obj.class.public_instance_methods.include? :get_records
					expect(assert2).to be_eq(true)
				end
				userfp = @valid_location + @user_metadata_filename
				expect(File.exist?(userfp)).to be_eq(true)
				users = Meta_data::load_yaml(userfp)
				expect(users).not_to be_nil
				orgfp = @valid_location + @org_metadata_filename
				expect(File.exist?(orgfp)).to be_eq(true)
				org = Meta_data::load_yaml(orgfp)
				expect(org).not_to be_nil


			end
		end
	end

	describe ".initialize" do
		context "zclient is nil " do
			it "should return nil " do
				api = Api_Methods.new(nil, @valid_location)
				expect(api).to be_nil
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
			it "upon an api call, we should be able to mark zclient as invalid" does
				#Please read!
				#if there is an auth error in the api, revoke token will be called
				#revoke token can mark if a token is bad.
				expect(false).to be_eq true
			end
		end
	end
end
