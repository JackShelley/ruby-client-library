require 'ZohoCRM_Client'
RSpec.describe ZohoCRMClient do
	def load_zclient_from_db(fp)
		return Meta_data::load_yaml(fp)
	end
	def save_zclient_in_db(obj, fp)
		Meta_data::dump_yaml(obj, fp)
	end
	it "has a version number" do
		expect(ZohoCRMClient::VERSION).not_to be nil
	end
	before do
		#@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.f00340154a3bf245e0dbd817e091f9da.42d1d9d42d1b06b513cb3e6fdc7b5365", "1000.5d80912adfcf5f10f6bd562d2adc62ec.4cd65eca6d89324a5b7e4e3818096fae", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		#last updated refresh token @zclient July 7 Friday
		@default_meta_folder = "/Users/kamalkumar/spec_meta_folder/"
		@conf_file = "/Users/kamalkumar/conf/config.yaml"
		@zclient, @apiObj = ZohoCRMClient.get_client_objects(@conf_file)
		#@apiObj = Api_Methods.new(@zclient, @default_meta_folder)
		@headers = @zclient.construct_headers
		@invalid_url = "something.com"
		@lObj = @apiObj.load_crm_module("Leads")
		@leads_url = Constants::DEF_CRMAPI_URL + "Leads"
		@accounts_url = Constants::DEF_ACCOUNTS_URL
		@revoketoken_path = "oauth/v2/token"
		@client_app = @zclient.get_client_app
		@tokens = @zclient.get_tokens
		@image_file_path = "/Users/kamalkumar/test_data/e1ed-5f07-4400-b8f6-7856472fcfc8.jpg"
		@valid_refresh_token = "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a67dfebe56ae6bb8"
		@invalid_accestoken = "lubvadu632hv9826t1bffw8y93fb"
		@invalid_refreshtoken = "345iudhiw7t769183hifbewoirwv"
		@zclient_fp = "/Users/kamalkumar/test/objects/zclient.yaml"
		save_zclient_in_db(@zclient, @zclient_fp)
	end
	describe "revoke_token" do
		context "Credentials are wrong" do
			it "should make the refresh token invalid and return false" do
				tokens = @zclient.get_tokens
				accesstoken = tokens.access_token
				refreshtoken = tokens.refresh_token
				@zclient.set_tokens(@invalid_refreshtoken, @invalid_accestoken)
				result = @zclient.revoke_token
				expect(result).to eq(false)
				tokens = @zclient.get_tokens
				is_valid = tokens.is_refreshtoken_valid
				expect(is_valid).to eq(false)

			end
		end
		context "Client app details and refreshtoken are valid" do
			it "should refresh accesstoken and return true" do
				@zclient = load_zclient_from_db(@zclient_fp)
				ZohoCRMClient.debug_log(@zclient.inspect)
				expect(@zclient).not_to be_nil
				temp_tokens = @zclient.get_tokens
				temp_bool = temp_tokens.is_refreshtoken_valid
				ZohoCRMClient.debug_log("is_refreshtoken_valid ==> #{temp_bool}")
				@zclient.set_access_token(@invalid_accestoken, true)
				result = @zclient.revoke_token
				expect(result).to eq(true)
				tokens = @zclient.get_tokens
				accesstoken = tokens.access_token
				url = @leads_url
				headers = @zclient.construct_header_for(accesstoken)
				params = {}
				response = @zclient._get(url, params, headers)

				#Assertion
				expect(response).not_to be_nil #1
		  		assert1 = false
		  		assert1 = response.class.public_instance_methods.include? :code
		  		expect(assert1).to eq(true) #2
		  		code = response.code
		  		expect(code).to eq(200) #3
		  		assert2 = false
		  		assert2 = response.class.public_instance_methods.include? :body
		  		expect(assert2).to be_truthy #4
		  		body = response.body
		  		expect(body).not_to be_empty
			end
		end
	end
	describe ".is_accesstoken_valid" do
		context "accesstoken is not valid" do
			it "should revoke the token and then return true" do
				@zclient.set_access_token(@invalid_accestoken)
				result = @zclient.is_accesstoken_valid
				expect(result).to eq(true)
				tokens = @zclient.get_tokens
				accesstoken = tokens.access_token
				headers = @zclient.construct_header_for(accesstoken)
				url = @leads_url
				response = @zclient._get(url, {}, headers)
				expect(response).not_to be_nil
				assert1 = false
	  		assert1 = response.class.public_instance_methods.include? :code
	  		expect(assert1).to eq(true) #2
	  		code = response.code
	  		expect(code).to eq(200)
	  		assert2 = false
	  		assert2 = response.class.public_instance_methods.include? :body
	  		expect(assert2).to eq(true)
	  		body = response.body
	  		expect(body).not_to be_empty
			end
			it "should return false if there was a problem in revoking the token" do
				@zclient.set_tokens(@invalid_refreshtoken, @invalid_accestoken)
				result = @zclient.is_accesstoken_valid
				expect(result).to eq(false)
			end
		end
		context "accesstoken is valid" do
			it "should return true" do
				tokens = @zclient.get_tokens
				accesstoken = tokens.access_token
				@zclient.set_tokens(@valid_refresh_token, accesstoken)
				result = @zclient.is_accesstoken_valid
				expect(result).to eq(true)
				temp_tokens = @zclient.get_tokens
				accesstoken = temp_tokens.access_token
				headers = @zclient.construct_headers
				url = @leads_url
				response = @zclient._get(url, {}, headers)
				expect(response).not_to be_nil
				assert1 = false
				assert1 = response.class.public_instance_methods.include? :code
				expect(assert1).to eq(true)
				code = response.code
				expect(code).to eq(200)
				assert2 = false
				assert2 = response.class.public_instance_methods.include? :body
				expect(assert2).to eq(true)
				body = response.body
			expect(body).not_to be_empty
			end
		end
	end

	describe "handle_response" do
		#handle_response(response)
		context "response is not of type RestClient::Response" do
			it "should return nil" do
				#response is nil
				response = nil
				result = @zclient.handle_response(response)
				expect(result).to be_nil
			end
			it "should return nil, response is a string" do
				response = "Non_Empty_String"
				result = @zclient.handle_response(response)
				expect(result).to be_nil
			end
		end
		context "Response with status code greater than or equal to 200 and less than 400" do
			it "should return response object, when status code is 200" do
				url = @leads_url
				headers = @zclient.construct_headers
				params = {}
				response = @zclient._get(url, params, headers)
				result = @zclient.handle_response(response)
				#Assertions
				expect(result).not_to be_nil #1
				assert1 = false
				assert1 = result.class.public_instance_methods.include? :code
				expect(assert1).to be_truthy #2
				code = result.code
				expect(code).to eq(200) #3
				assert2 = false
				assert2 = result.class.public_instance_methods.include? :body
				expect(assert2).to be_truthy #4
				body = result.body
				expect(body).not_to be_empty
			end
		end
		context "when the status code is 400 " do
			it "should return the response intact, when status is 400 " do
				url = @leads_url + Constants::URL_PATH_SEPERATOR + "upsert"
				headers = @zclient.construct_headers
				params = {}
				#_get throws an exception
				response = @zclient._get(url, params, headers)
				result = @zclient.handle_response(response)
				#New Assertions
				expect(result).to be_nil

			end
		end
		context "Status code is 401 but refreshtoken is valid " do
			it "should return the error response intact, signifying us to go for a retry" do
				#Throws an exception: We need to catch and progress
				url = @leads_url
				@zclient.set_access_token(@invalid_accestoken)
				headers = @zclient.construct_header_for(@invalid_accestoken)
				result = nil
				begin
					response = RestClient.get(url, headers)
				rescue => e
					result = @zclient.handle_response(e)
				end
				#TOCHECK

				#Assertions
				#expect(result).to be_an_instance_of(RestClient::Unauthorized)
				expect(result).not_to be_nil
				code = result.code
				expect(code).to eq(401)
				body = result.body
				expect(body).not_to be_empty
				access_token_valid = @zclient.is_accesstoken_valid
				expect(access_token_valid).to eq(true)
			end
		end
		context "Status code is 401 but refreshtoken is not valid " do
			it "should return nil, and mark the tokens as invalid" do
				#RestClient throws exception in case of a 401 access.
				#@zclient.set_access_token(@invalid_accestoken, true)
				@zclient.set_tokens(@invalid_accestoken, @invalid_refreshtoken)
				url = @leads_url
				headers = @zclient.construct_header_for(@invalid_accestoken)
				begin
					result = RestClient.get(url, headers)
				rescue => e
					result = @zclient.handle_response(e)
				end
				#New Assertions
				expect(result).to be_nil	
				tokens = @zclient.get_tokens
				expect(tokens.is_refreshtoken_valid).to eq(false)
				@zclient = load_zclient_from_db(@zclient_fp)

=begin #old code
				response = @zclient._get(url, params, headers)
				result = @zclient.handle_response(response)
				
				#Assertions
				expect(result).not_to be_nil #1
				assert1 = false
				assert1 = result.class.public_instance_methods.include? :code
				expect(assert1).to be_truthy #2
				code = result.code
				expect(code).to eq(401) #3
				assert2 = false
				assert2 = result.class.public_instance_methods.include? :body
				expect(assert2).to be_truthy #4
				body = result.body
				expect(body).not_to be_empty

				headers = @zclient.construct_headers
				response = @zclient._get(url, params, headers)
				#Assertions
				expect(result).not_to be_nil #1
				assert1 = false
				assert1 = result.class.public_instance_methods.include? :code
				expect(assert1).to be_truthy #2
				code = result.code
				expect(code).to eq(200) #3
				assert2 = false
				assert2 = result.class.public_instance_methods.include? :body
				expect(assert2).to be_truthy #4
				body = result.body
				expect(body).not_to be_empty
				expect(false).to be_eq(true)
=end
			end
		end
		
	end #describe "handle_response"

	describe "._delete" do
	  	context "Given an empty url " do
	  		it "should return nil" do
	  			response = @zclient._delete("",{},{})
	  			expect(response).to be_nil
	  		end
	  	end
	  	context "headers is empty" do
	  		it "should return nil" do
	  			url = @leads_url
	  			headers = {}
	  			params = {}
	  			response = @zclient._delete(url, params, headers)
	  		end
	  	end
	  	context "invalid url" do
	  		it "should return nil" do
	  			url = @invalid_url
	  			headers = @zclient.construct_headers
	  			params = {}
	  			result = @zclient._delete(url, params, headers)
	  			expect(result).to be_nil
	  		end
	  	end
	  	context "valid call" do
	  		it "should return RestClient::Response object with code 200 " do
	  			url = @leads_url
	  			records = @lObj.get_records(1)
	  			new_record = nil
	  			new_id = nil
	  			records.each do |id,record|
	  				new_record = record
	  				new_id = id
	  			end
	  			ids = new_id
	  			params = {}
	  			params['ids'] = ids
	  			headers = @zclient.construct_headers
	  			response = @zclient._delete(url, params, headers)
	  		end
	  	end
  	end

	describe "._post" do
		context "Given an empty url" do
			it "should return nil" do
				response = @zclient._post("", {}, {})
				expect(response).to be_nil
			end
		end
		#Please read!
		#We use this function only for connecting Accounts URLs alone.
		#All Accounts URLs have parameters with them.
		context "params are empty " do
			it "should return nil" do
				url = @accounts_url
				params = {}
				headers = @zclient.construct_headers
				response = @zclient._post(url, params, headers)
				expect(response).to be_nil
			end
		end
		context "Invalid url given" do
			it "should return nil " do
				url = @invalid_url
				params = {}
				params[:client_id] = @client_app.client_id
				params[:client_secret] = @client_app.client_secret
				params[:grant_type] = 'refresh_token'
				params[:refresh_token] = @tokens.refresh_token
				headers = {}
				response = @zclient._post(url, params, headers)
				expect(response).to be_nil
			end
		end
		context "headers are empty " do
			it "should return if there's is any response " do 
				url = @accounts_url + @revoketoken_path
				params = {}
				params[:client_id] = @client_app.client_id
				params[:client_secret] = @client_app.client_secret
				params[:grant_type] = 'refresh_token'
				params[:refresh_token] = @tokens.refresh_token
				headers = {}
				response = @zclient._post(url, params, headers)
				#Assertion
				expect(response).not_to be_nil #1
		  		assert1 = false
		  		assert1 = response.class.public_instance_methods.include? :code
		  		expect(assert1).to be_truthy #2
		  		code = response.code
		  		expect(code).to eq(200) #3
		  		assert2 = false
		  		assert2 = response.class.public_instance_methods.include? :body
		  		expect(assert2).to be_truthy #4
		  		body = response.body
		  		expect(body).not_to be_empty
			end
		end
		context "valid call" do
			it "should return response if any " do
				url = @accounts_url + @revoketoken_path
			params = {}
			params[:client_id] = @client_app.client_id
			params[:client_secret] = @client_app.client_secret
			params[:grant_type] = 'refresh_token'
			params[:refresh_token] = @tokens.refresh_token
			headers = {}
			response = @zclient._post(url, params, headers)
			#Assertion
			expect(response).not_to be_nil #1
	  		assert1 = false
	  		assert1 = response.class.public_instance_methods.include? :code
	  		expect(assert1).to be_truthy #2
	  		code = response.code
	  		expect(code).to eq(200) #3
	  		assert2 = false
	  		assert2 = response.class.public_instance_methods.include? :body
	  		expect(assert2).to be_truthy #4
	  		body = response.body
	  		expect(body).not_to be_empty
			end
		end
	end #describe "_post"
	describe "._update_put" do
		context "Given an empty url" do
			it "should returns nil" do
				response = @zclient._update_put("", {}, {})
				expect(response).to be_nil
			end
		end
		context "headers or payload is empty" do 
			it "should return nil" do
				#1
				url = @leads_url
				headers = {}
				payload = nil
				response = @zclient._update_put(url, headers, payload)
				expect(response).to be_nil

				#2
				headers = @zclient.construct_headers
				payload = nil
				response = @zclient._update_put(url, headers, payload)
				expect(response).to be_nil

				#3
				headers = {}
				records = @lObj.get_records(1)
				new_record = nil
				records.each do |id, record_obj|
					new_record = record_obj
				end
				new_record.setfield_byname("Last_name", "Updated_Last_Name")
				hsh = new_record.construct_update_hash
				arr = []
				arr[0] = hsh
				final_hash = {}
				final_hash['data'] = arr
				payload = JSON::generate(final_hash)
				response = @zclient._update_put(url, headers, payload)
				expect(response).to be_nil

				#4
				headers = @zclient.construct_headers
				payload = ""
				response = @zclient._update_put(url, headers, payload)
				expect(response).to be_nil
			end
		end
		context "url is an invalid url" do
			it "should return nil " do
				url = @invalid_url
				headers = @zclient.construct_headers
				payload = "Non_Empty_String"
				result = @zclient._update_put(url, headers, payload)
				expect(result).to be_nil
			end
		end
		context "valid call" do
			it "should return RestClient::Response object with a code 200 or 201 or 202" do
				url = @leads_url
				headers = @zclient.construct_headers
				records = @lObj.get_records(1)
				new_record = nil
				records.each do |id, record_obj|
					new_record = record_obj
				end
				new_record.setfield_byname("Last_name", "Updated_Last_Name")
				hsh = new_record.construct_update_hash
				arr = []
				arr[0] = hsh
				final_hash = {}
				final_hash['data'] = arr
				payload = JSON::generate(final_hash)
				response = @zclient._update_put(url, headers, payload)
				#Assertions
				expect(response).not_to be_nil #1
		  		assert1 = false
		  		assert1 = response.class.public_instance_methods.include? :code
		  		expect(assert1).to be_truthy #2
		  		code = response.code.to_i
		  		code.should be >= 200
		  		code.should be <= 202
		  		#expect(code).to eq(200) #3
		  		assert2 = false
		  		assert2 = response.class.public_instance_methods.include? :body
		  		expect(assert2).to be_truthy #4
		  		body = response.body
		  		expect(body).not_to be_empty
			end
		end
	end #describe update_put

	describe "._upsert_post" do
		context "Given an empty url" do
			it "should return nil" do
				response = @zclient._upsert_post("", {}, {})
				expect(response).to be_nil
			end
		end

		context "headers is empty " do
			it "should return nil" do
				url = Constants::DEF_CRMAPI_URL + "Leads"
				headers = {}
				params = {}
				params["fields"] = "Last_name"
				response = @zclient._upsert_post(url, params, headers)
				expect(response).to be_nil
			end
		end

		context "payload is nil" do
			it "should return nil " do
				url = Constants::DEF_CRMAPI_URL + "Leads"
				headers = @zclient.construct_headers
				params = {}
				payload = nil
				response = @zclient._upsert_post(url, params, headers, payload)
				expect(response).to be_nil
			end
		end

		context "Given url is an invalid url" do
			it "should return nil" do
				url = @invalid_url
				params = {}
				headers = @zclient.construct_headers
				payload = "Non_Empty_String"
				result = @zclient._upsert_post(url,params,headers)
				expect(result).to be_nil
			end
		end

		context "Valid call" do
			it "Should return response" do
				url = Constants::DEF_CRMAPI_URL + "Leads"
				headers = @zclient.construct_headers
				params = {}
				records = @lObj.get_records(1)
				new_record = nil
				records.each do |id, record_obj|
					new_record = record_obj
				end
				new_record.setfield_byname("Last_name", "Updated_Last_Name")
				hsh = new_record.construct_update_hash
				arr = []
				arr[0] = hsh
				final_hash = {}
				final_hash['data'] = arr
				payload = JSON::generate(final_hash)
				response = @zclient._upsert_post(url, params, headers, payload)
				#Testing the response for correctness
				expect(response).not_to be_nil #1
		  		assert1 = false
		  		assert1 = response.class.public_instance_methods.include? :code
		  		expect(assert1).to be_truthy #2
		  		code = response.code.to_i
		  		temp = false
		  		if code >= 200 && code <=202 then
		  			temp = true
		  		end
		  		expect(temp).to eq(true) #3
		  		assert2 = false
		  		assert2 = response.class.public_instance_methods.include? :body
		  		expect(assert2).to be_truthy #4
		  		body = response.body
		  		expect(body).not_to be_empty
			end
		end
	end

	describe "._get" do
		context "Given an empty url" do
			it "should returns nil" do
				response = @zclient._get("", {}, {})
				expect(response).to be_nil
			end
		end
		context "headers is empty " do
			it "should fail" do
				url = ""
				response = @zclient._get(url, {}, {})
				expect(response).to be_nil
			end
		end
		context "url is an invalid url" do
			it "should return nil " do 
				headers = @zclient.construct_headers
				response = @zclient._get(@invalid_url, {}, headers)
				expect(response).to be_nil
			end
		end
		context "Valid url: get Leads url" do
		  	it "makes a Net::Http::Get call for the given uri, params and headers " do 
		  		headers = @zclient.construct_headers
		  		response = @zclient._get(@leads_url, {}, headers)
		  		expect(response).not_to be_nil #1
		  		assert1 = false
		  		assert1 = response.class.public_instance_methods.include? :code
		  		expect(assert1).to be_truthy #2
		  		code = response.code
		  		expect(code).to eq(200) #3
		  		assert2 = false
		  		assert2 = response.class.public_instance_methods.include? :body
		  		expect(assert2).to be_truthy #4
		  		body = response.body
		  		expect(body).not_to be_empty
		  	end
		end
	end #describe "._get"



=begin
	
=end


end #last end - describe "ZohoCRMClient"