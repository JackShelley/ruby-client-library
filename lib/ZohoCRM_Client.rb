require "ZohoCRM_Client/version"
require 'Constants'
require 'rest-client'
require 'time'
require 'net/http/post/multipart'
require 'json'
require 'ZohoAPIMethod'
require 'ZCRMModule'
require 'ZCRMField'
require 'ZCRMRecord'
require 'ZohoException'
require 'ZCRMLayout'
require 'ZCRMNote'

class ZohoCRMClient

	def self.log(msg="")
		print "Log from caller ::: " + caller[0]
		print "\n"
		print msg, "\n"
	end

	def self.debug_log(msg="")
		print msg, "\n"
		print "----------------- Above message is a debug log from caller ::: " + caller[0]
		print "\n"
	end

	def self.get_client_objects(file_path)
		if !File.exists?(file_path) then
			return nil, nil
		end
		accepted_domains = ["com", "eu", "cn"]
		conf_obj = Meta_data.load_yaml(file_path)
		client_id = conf_obj['client_id']
		client_secret = conf_obj['client_secret']
		redirect_uri = conf_obj['redirect_uri']
		refresh_token = conf_obj['refresh_token']
		access_token = conf_obj['access_token']
		domain = conf_obj['domain']
		if !accepted_domains.include?(domain) then
			return nil, nil
		end
		has_log_file = conf_obj['has_log_file']
		log_file = conf_obj['log_file']
		if has_log_file then
			if !File.exists?(log_file) then
				has_log_file = false
			end
		end
		zclient = ZohoCRMClient.new(client_id, client_secret, refresh_token, access_token, redirect_uri, domain, has_log_file, log_file)
		meta_folder = conf_obj['meta_folder']
		apiObj = nil
		if File.exists?(meta_folder) then
			apiObj = Api_Methods.new(zclient, meta_folder)
		end
		return zclient, apiObj
	end

	def initialize(client_id="", client_secret="", refresh_token="", access_token="", redirect_uri="", domain="", has_log_file=false, log_file="")
		@client_app = ClientAppDetails.new(client_id, client_secret, redirect_uri)
		if refresh_token.empty? then
			refresh_token = Constants::TOBEGENERATED
			access_token = Constants::TOBEGENERATED
		elsif access_token.empty? then
			access_token = Constants::TOBEGENERATED
		end
		@tokens = Tokens.new(refresh_token, access_token)
		@api_limits = nil
		@domain = domain
		@has_log_file = has_log_file
		@log_file = log_file

	end

	def get_domain
		return @domain
	end

	def get_api_limits
		return @api_limits
	end

	def set_api_limits(limits)
		if limits.class == APILimits then
			@api_limits = limits
		end
	end

	def self.getcurtimeinmillis
		return (Time.now.to_f * 1000).to_i
	end

	def set_access_token(access_token, testing = false)
		if !testing then
			return
		else
			refresh = @tokens.refresh_token
			access = @tokens.access_token
			set_tokens(refresh, access_token)
		end
	end

	def get_client_app
		return @client_app
	end

	def get_tokens
		return @tokens
	end

	def set_tokens(refresh_token="", access_token="")
		if refresh_token.empty? then
			refresh_token = Constants::TOBEGENERATED
			access_token = Constants::TOBEGENERATED
		elsif access_token.empty? then
			access_token = Constants::TOBEGENERATED
		end
		@tokens = Tokens.new(refresh_token, access_token)
	end

	#def _get(url="", params={}, headers={})
	#def _upsert_post(url="", params={}, headers={}, payload=nil)
	#def _update_put(url="", headers={}, payload=nil)
	#def _post(url="", params={}, headers={})#, payload="")
	#def _post_multipart(url="", headers={}, multipart_file="")
	#def _put(url="", params={}, headers={}, payload)


	#safe_get function is not used anywhere, We could use it if situation demands it.
	def safe_get(url="", params={}, headers={})
		if headers.nil? || headers.empty? then
			headers = self.construct_headers
		end
		r = _get(url, params, headers)
		if r.nil? then
			return nil
		end
		code = r.code.to_i
		if code == 401 then
			headers = self.construct_headers
			return _get(url, params, headers)
		end
		if code == 429 then
			headers = self.construct_headers
			return _get(url, params, headers)
		end
		return r
	end


	## Makes a HTTP::Get request to the URL along with given params, headers
	def _get(url="", params={}, headers={})
		if url.empty? then
			return nil
		end
		if headers.empty? then
			return nil
		end
		if !params.empty? then
			headers["params"] = params
		end
		#ZohoCRMClient.debug_log("Inside _get function")
		#ZohoCRMClient.debug_log("URL ===> #{url}")
		#ZohoCRMClient.debug_log("Params ===> #{params}")
		#ZohoCRMClient.debug_log("caller ===> #{caller[0]}\n#{caller[1]}\n#{caller[2]}")
		begin
			response = RestClient.get(url, headers)
			#ZohoCRMClient.debug_log("Resonse code, class, body ==> #{response.code}, #{response.class}, #{response.body}")
			#ZohoCRMClient.debug_log("Response ===> #{response}")
		rescue => e
			ZohoCRMClient.debug_log("Exception occurred while trying for ==> #{url} \n
				Exception class, self ===> #{e.class}, #{e}")
		 	return error_response(e)
		end
		return handle_response(response)
	end

	def safe_upsert_post(url="", params={}, headers={}, payload=nil)
	#todo:commentout: we have handled these cases inside function ZCRMModule.upsert
		res = _upsert_post(url, params, headers, payload)
		ZohoCRMClient.debug_log("Response after first call ==> #{res}")
		code = res.code.to_i
		if code == 401 then
			ZohoCRMClient.debug_log("Inside 401 code if block ")
			if self.revoke_token then
				ZohoCRMClient.debug_log("Token successfully revoked ===> ")
				ZohoCRMClient.debug_log("Now we are going for another call ==> ")
				headers = self.construct_headers
				response = _upsert_post(url, params, headers, payload)
				ZohoCRMClient.debug_log("The returned response is ===> #{response}")
				return response
			else
				raise InvalidTokensError.new()
			end
		elsif code == 400 then
			raise BadRequestException.new()
		elsif code == 429 then
			ZohoCRMClient.debug_log("Code 429 while carrying out upsert_post : Hence we are going to update apilimits")
			ZohoCRMClient.debug_log("Printing api_limits object before updating ===> #{@api_limits}")
			self.update_limits_HTTPRESPONSE(res)
			ZohoCRMClient.debug_log("Printing api_limits object after updating ===> #{@api_limits}")
			headers = self.construct_headers
			return _upsert_post(url, params, headers, payload)
		end
		return res
	end

	def _upsert_post(url="", params={}, headers={}, payload=nil)
		if url.empty? then
			ZohoCRMClient.log("Function upsert_post called with an empty url ::: ")
			return nil
		end
		if headers.nil? || headers.empty? then
			return nil
		end
		if payload.nil? || payload.empty? then
			return nil
		end

		ZohoCRMClient.debug_log("Printing headers ===> #{headers}")
		
		begin
			uri = URI(url)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
		    req = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
		    headers.each do |key, value|
		    	req.add_field(key, value)
		    end
		    if !payload.nil? then
		    	req.body = payload
		    end
		    res = http.request(req)
		    ZohoCRMClient.debug_log("HTTP status code ==> #{res.code}")
		rescue => e
			puts "Exception in _post_with_body === > "
			puts "\n"
			puts "Printing backtrace ====> " << "\n"
		    puts "failed #{e}"
		    puts "\n"
		    puts e.backtrace
		    puts "\n"
		    return nil
		end
		return res
	end

	def update_limits_HTTPRESPONSE(res)
		if @api_limits.nil? then
			raise StandardError.new("Api Limits is nil while calling update_put : ")
		else
			@api_limits.update_apilimits_HTTPRESPONSE(res)
		end
	end

	def safe_update_put(url="", headers={}, payload=nil)
		res = _update_put(url, headers, payload)
		ZohoCRMClient.debug_log("Response after first call ===> #{res}")
		code = res.code.to_i
		if code == 401 then
			ZohoCRMClient.debug_log("Inside 401 code if block ==> ")
			if self.revoke_token then
				ZohoCRMClient.debug_log("Token successfully revoked ===> ")
				ZohoCRMClient.debug_log("Now we are going for another call ==> ")
				headers = self.construct_headers
				response = _update_put(url, headers, payload)
				ZohoCRMClient.debug_log("The returned response is ====> #{response}")
				return response
			else
				raise InvalidTokensError.new()
			end
		elsif code == 400 then
			raise BadRequestException.new()
		elsif code == 429 then
			ZohoCRMClient.debug_log("code 429 while carrying out update_put : Hence we are going to update apilimits ")
			ZohoCRMClient.debug_log("Printing api_limits object before updating ===> #{@api_limits}")
			self.update_limits_HTTPRESPONSE(res)
			ZohoCRMClient.debug_log("Printing api_limits object after updating ===> #{@api_limits}")
			headers = self.construct_headers
			return _update_put(url, headers, payload)
		end
		return res
	end

	def _update_put(url="", headers={}, payload=nil)
		if url.empty? then
			ZohoCRMClient.log("_update_put called with empty url. Hence returning nil.")
			return nil
		end
		if headers.empty? || payload.nil? || payload.empty? then
			ZohoCRMClient.log("_update_put called with empty headers or payload. Hence, returning nil.")
			return nil
		end
		begin
			uri = URI(url)
			http = Net::HTTP.new(uri.host, uri.port)
			http.use_ssl = true
		    req = Net::HTTP::Put.new(uri.path, 'Content-Type' => 'application/json')
		    headers.each do |key, value|
		    	req.add_field(key, value)
		    end
		    if !payload.nil? then
		    	req.body = payload
		    end
		    res = http.request(req)
		    code = res.code
		    ZohoCRMClient.debug_log("code ===> #{code}")

		rescue => e
			puts "Exception in _post_with_body === > "
			puts "\n"
			puts "Printing backtrace ====> " << "\n"
		    puts "failed #{e}"
		    puts "\n"
		    puts e.backtrace
		    puts "\n"
		end
		return res
	end

	## Makes a HTTP::Post request to the URL along with given params, header and raw-content payload
	def _post(url="", params={}, headers={})#, payload="")
		if url.nil? || url.empty? then
			return nil
		end
		if params.empty? then
			return nil
		end
		begin
			response = RestClient.post(url, params, headers)
		rescue Exception => e
			ZohoCRMClient.debug_log("Exception in _post function :: Printing stack trace ::")
			ZohoCRMClient.debug_log(e.message)
			ZohoCRMClient.debug_log(e.backtrace.inspect)
			return nil
		end
		#handle_response(response)
	end

	def _post_multipart(url, file_path, headers)
		url = URI.parse('https://www.zohoapis.com/crm/v2/Accounts/297527000005241003/Attachments')
		pdf = File.open("/Users/kamalkumar/Downloads/PDFDocument.pdf")
		http = Net::HTTP.new(url.host, url.port)
		http.use_ssl = (url.scheme == "https")
		req = Net::HTTP::Post::Multipart.new url.path, "file" => UploadIO.new(pdf, "image/pdf", "file")
		req.add_field("Authorization", "Zoho-oauthtoken 1000.c6b1277122be1affd1ccd38cee3bad4d.a533d0595136df653ee4d4e588a19240")
		res = http.request(req)
		puts res.body
	end

	## Special handling if the API params involve a multipart payload::: For Upload attachment | photo API
	def _post_multipart1(url="", headers={}, multipart_file="")
		if url.empty? then
			ZohoCRMClient.log("_post_multipart called with an empty url. Hence, returning nil")
			return nil
		end
		if headers.empty? then
			ZohoCRMClient.log("_post_multipart called with empty headers. Hence, returning nil")
			return nil
		end
		begin
			f = File.new(multipart_file, 'rb')
		rescue Exception => e  ##{TODO: This message will be caught and directed to the user. For now, I am printing it here, since we do not have full structure for the gem}
			ZohoCRMClient.log("Error Occurred while opening the multipart payload. Please check the file url again. ")
			ZohoCRMClient.log(e.message)
			return nil
		end
		begin
			response = RestClient.post url, {:file => File.new(multipart_file, 'rb'), :multipart=>true}, headers
		rescue => e
			return error_response(e)
		end
		handle_response(response)
	end

	## Makes a HTTP::Put request to the URL along with given params, header and raw-content payload
	def _put(url="", params={}, headers={}, payload)
		if !params.empty? then
			headers[:params] = params
		end
		response = RestClient.put(url, payload, headers)
		handle_response(response)
	end

=begin
	def safe_get(url="", params={}, headers={})
		if headers.nil? || headers.empty? then
			headers = self.construct_headers
		end
		r = _get(url, params, headers)
		if r.nil? then
			return nil
		end
		code = r.code.to_i
		if code == 401 then
			headers = self.construct_headers
			return _get(url, params, headers)
		end
		if code == 429 then
			headers = self.construct_headers
			return _get(url, params, headers)
		end
		return r
	end
=end

	def safe_delete(url="", params={}, headers={})
		if headers.nil? || headers.empty? then
			headers = self.construct_headers
		end
		r = self._delete(url, params, headers)
		if r.nil? then
			return nil
		end
		code = r.code.to_i
		if code == 401 then
			headers = self.construct_headers
			return self._delete(url, params, headers)
		elsif code == 429 then
			headers = self.construct_headers
			return self.delete(url, params, headers)
		end
		return r
	end

	## Makes a HTTP::Put request to the URL along with given params, header
	def _delete(url="", params={}, headers={})
		if url.empty? then
			return nil
		end
		if headers.empty? then
			return nil
		end
		if !params.empty? then
			headers[:params] = params
		end
		begin
			response = RestClient.delete(url, headers)
		rescue => e
			return error_response(e)
		end
		handle_response(response)
	end

	def error_response(e)
		if e.nil? then
			ZohoCRMClient.debug_log("handle_exception called with nil object. Hence returning nil.")
			return nil
		end
		if e.class == SocketError then
			ZohoCRMClient.debug_log("Error raised because of an invalid url api call, resulting in a SocketError. Hence returning nil.")
			return nil
		end
		if !e.respond_to?(:http_code, true) then
			ZohoCRMClient.debug_log("e is not of type RestClient exceptions ")
			return nil
		end
		code = e.http_code
		r = e.response
		body = r.body
		ZohoCRMClient.debug_log("Code ===> #{code}")
		ZohoCRMClient.debug_log("Body ===> #{body}")
		if code == 401 
			ZohoCRMClient.log("Unauthorized request : resulting in failure")
			body_json = e.response.body
			body = JSON.parse(body_json)
			error_msg = body["code"] #INVALID_TOKEN
			if error_msg == Constants::INVALID_TOKEN_MSG then
				temp = revoke_token
				if temp
					return e.response
				elsif !temp
					return nil
				end
			end
		elsif code == 400
			ZohoCRMClient.log("Bad Request : resulting in failure")
			ZohoCRMClient.debug_log("Printing caller stack : \n #{caller.inspect}")
			return nil
		elsif code == 429
			ZohoCRMClient.debug_log("Too many requests hence updating api limits ==> #{e}")
			if @api_limits.nil? then
				@api_limits = APILimits.new(r)
			else
				@api_limits.update_api_limits(r)
			end
			return e.response
		end
	end

	## Checks API response for success, Panics in case of errors
	def handle_response(response)

		if response.class != RestClient::Response then
			ZohoCRMClient.debug_log("Response to be handled is an exception ===> #{response}")
			return error_response(response)
		end
		if response.nil? then
			ZohoCRMClient.log("handle_response called with nil. Hence returning nil.")
			return nil
		end
		code = response.code
		if code.class != Integer then
			code = code.to_i
		end

		#ZohoCRMClient.debug_log("Printing code for debugging purpose ===> #{code}")

		#old code
		is_success = false
		if code >= 200 && code < 400 then
			is_success = true
		elsif code == 401 then
			if revoke_token
				puts "Renewed access_token in place. Please try again"
			else
				puts "Failure" << "\n" 
				panic "Access token refresh failed...\n"
			end
		elsif code == 400 then
			ZohoCRMClient.log("Bad request: failure")
		else 
			puts "Failure"
		end

		if @api_limits.nil? then
			@api_limits = APILimits.new(response)
		else
			@api_limits.update_api_limits(response)
		end

		return response
	end

	def is_accesstoken_valid
		if !@tokens.is_refreshtoken_valid.nil? && @tokens.is_refreshtoken_valid == false then
			return false
		end

		if @tokens.expiry_time_insec == 0 then
			res = self.revoke_token #TODO: We need to call another api to find out the expiry time ## Validate tokens
			return res
		end

		res = false
		t = Time.new.to_i

		#ZohoCRMClient.debug_log("Printing (current time in sec), (expiry_time_insec) ===> (#{t}) , (#{@tokens.expiry_time_insec})")
		if t < @tokens.expiry_time_insec
			res = true
		elsif self.revoke_token
			if @tokens.is_refreshtoken_valid
				res = true
			else
				res = false
			end
		else
			res = false
		end
		return res
	end

	def get_sleep_secs
		result = 0
		if @api_limits.nil? then
			result = 0
			#if !self.apilimit_update then
				#raise APILimitsException.new()
			#end
		else
			result = @api_limits.getsleeptime
		end
		return result
	end

	def construct_headers
		if !self.is_accesstoken_valid then
			raise InvalidTokensError.new()
		end

		if @api_limits.nil? then
			ssecs = 0
		else
			ssecs = @api_limits.getsleeptime
		end
		if ssecs > 0 then
			ZohoCRMClient.log("Thread is put to sleep for #{ssecs} seconds")
			sleep(ssecs)
		end
		headers = {}
		auth_str = 'Zoho-oauthtoken ' + @tokens.access_token
		headers[:Authorization] = auth_str 
		return headers
	end

	def construct_header_for(access_token)
		headers = {}
		auth_str = 'Zoho-oauthtoken ' + access_token
		headers[:Authorization] = auth_str 
		return headers
	end

	def revoke_token
		#ZohoCRMClient.debug_log("Revoke_called :: from :: #{[caller[0],caller[1]]}")
		res = false
		revoketoken_path = "oauth/v2/token"
		#url = Constants::DEF_ACCOUNTS_URL + revoketoken_path
		url = Constants::ACCOUNTS_URL + @domain +  Constants::URL_PATH_SEPERATOR + revoketoken_path
		params = {}
		params[:client_id] = @client_app.client_id
		params[:client_secret] = @client_app.client_secret
		params[:grant_type] = 'refresh_token'
		params[:refresh_token] = @tokens.refresh_token
		headers = {}
		cur_t = Time.new.to_i
		response = _post(url, params, headers)
		code = response.code
		json = response.body

		res_hash = JSON.parse(json)

		if code == 200 && !res_hash.has_key?('error') then
			access_token = res_hash['access_token']
			exp_in_sec = res_hash['expires_in_sec']
			api_domain = res_hash['api_domain'] ##Do We need this? Im not sure, if we need it we can use it later
			exp_time = cur_t + 3600
			@tokens.expiry_time_insec = exp_time
			@tokens.access_token = access_token
			@tokens.is_refreshtoken_valid = true
			res = true
		else
			ZohoCRMClient.debug_log("Problem revoking token ::: refresh_token isn't valid")
			@tokens.is_refreshtoken_valid = false
			res = false
		end
		return res
	end

	def self.panic (msg = "Please handle...")
		print "Do Not Know how to handle this, hence panicking ::: ", "\n"
		print "Here is what you are looking for ::: ", msg, "\n"
		raise msg
	end

	def self.handle_exception(e, message)
		print message, "\n"
		print 'Exception caught here, not gonna throw ::: So printing trace here', '\n'
		print e.message, '\n'
		print e.backtrace.inspect, '\n'
	end

	def apilimit_update
		#Modules api is common for all account and should not be a problem
		if !self.is_accesstoken_valid then
			raise InvalidTokensError.new()
		end
		url = Constants::DEF_CRMAPI_URL + "settings/modules"
		access_token = @tokens.access_token
		headers = self.construct_header_for(access_token)
		response = self.safe_get(url, {}, headers)
		if !response.nil? then
			code = response.code.to_i
			if code < 400 then
				result = true
			elsif code == 429 then
				result = true
			else
				result = false
			end
		end
		return result
	end

	def raiseDayLimitTest#todo: comment out
		if @api_limits.nil? then
			self.apilimit_update
		end
		lastupdtime = @api_limits.get_lastupdtime
		raise DayLimitExceeded.new(lastupdtime)
	end
	def badRequestTest#todo: comment out
		raise BadRequestException.new()
	end
end



## Abstraction for details associated with the Client App being used
## ** The member functions will grow as needed
class ClientAppDetails
	attr_accessor :client_id, :client_secret, :redirect_uri
	def initialize(client_id, client_secret, redirect_uri)
		@client_id = client_id
		@client_secret = client_secret
		@redirect_uri = redirect_uri
	end
end

## Abstraction for the OAuth tokens
class Tokens
	attr_accessor :refresh_token, :access_token, :is_accesstoken_expired, :expiry_time_insec, :is_refreshtoken_valid
	def initialize(refresh_token=Constants::TOBEGENERATED, access_token=Constants.TOBEGENERATED, scope="None")
		@access_token = access_token
		@refresh_token = refresh_token
		if refresh_token == Constants::TOBEGENERATED then
			@is_auth_complete = false
		end
		@is_accesstoken_expired = nil
		@expiry_time_insec = 0
		@is_refreshtoken_valid = nil
	end
end

## API Limits, (daily and window limits)
## We will be checking limits before api calls, to avoid unnessary failed calls
class APILimits
	attr_accessor :x_daylimit_remaining, :x_daylimit, :x_ratelimit, :x_ratelimit_remaining, :x_ratelimit_reset, :lastupdtime
	def initialize(response)
		if response.class != RestClient::Response then
			return nil
		end
		headers = response.headers	
		@x_daylimit_remaining = headers[:x_ratelimit_day_remaining]#.to_i
		@x_daylimit = headers[:x_ratelimit_day_limit]#.to_i
		@x_ratelimit = headers[:x_ratelimit_limit]#.to_i
		@x_ratelimit_remaining = headers[:x_ratelimit_remaining]#.to_i
		@x_ratelimit_reset = headers[:x_ratelimit_reset]#.to_i
		@lastupdtime = Time.now.to_i
	end

	def update_api_limits(response)
		headers = response.headers
		if !headers.has_key?(:x_ratelimit_day_remaining) then
			return
		end
		if headers[:x_ratelimit_day_remaining].nil? then
			ZohoCRMClient.debug_log("response headers are not proper ==> #{headers}")
			ZohoCRMClient.debug_log("Printing the response ==> #{response}")
		else
			temp = headers[:x_ratelimit_day_remaining]
			@x_daylimit_remaining = headers[:x_ratelimit_day_remaining]#.to_i
		end
		ZohoCRMClient.debug_log("Inside update_api_limits x_ratelimit_day_remaining ===> #{@x_daylimit_remaining}")
		@x_daylimit = headers[:x_ratelimit_day_limit]#.to_i
		@x_ratelimit = headers[:x_ratelimit_limit]#.to_i
		@x_ratelimit_remaining = headers[:x_ratelimit_remaining]#.to_i
		@x_ratelimit_reset = headers[:x_ratelimit_reset]#.to_i
		@lastupdtime = Time.now.to_i
		ZohoCRMClient.debug_log("Inside update_api_limits ===> #{self}")
	end

	def update_api_limits1(response)
		headers = response.headers
		@x_daylimit_remaining = headers[:x_ratelimit_day_remaining]#.to_i
		ZohoCRMClient.debug_log("Inside update_api_limits x_ratelimit_day_remaining ===> #{@x_daylimit_remaining}")
		@x_daylimit = headers[:x_ratelimit_day_limit]#.to_i
		@x_ratelimit = headers[:x_ratelimit_limit]#.to_i
		@x_ratelimit_remaining = headers[:x_ratelimit_remaining]#.to_i
		@x_ratelimit_reset = headers[:x_ratelimit_reset]#.to_i
		@lastupdtime = Time.now.to_i
		ZohoCRMClient.debug_log("Inside update_api_limits ===> #{self}")
	end

	def update_apilimits_HTTPRESPONSE(response)
		headers = response.to_hash
		if headers.has_key?("x_ratelimit_day_remaining") then
			@x_daylimit_remaining = headers["x_ratelimit_day_remaining"]
			ZohoCRMClient.debug_log("Inside update_apilimits_HTTPRESPONSE x_ratelimit_day_remaining ===> #{@x_daylimit_remaining}")
			@x_daylimit = headers["x_ratelimit_day_limit"]
			@x_ratelimit = headers["x_ratelimit_limit"]
			@x_ratelimit_remaining = headers["x_ratelimit_remaining"]
			@x_ratelimit_reset = headers["x_ratelimit_reset"]
			@lastupdtime = Time.now.to_i
			ZohoCRMClient.debug_log("Inside update_apilimits_HTTPRESPONSE ===> #{self}")
		end
=begin
		@x_daylimit_remaining = response.header("x_ratelimit_day_remaining")
		ZohoCRMClient.debug_log("Inside update_apilimits_HTTPRESPONSE x_ratelimit_day_remaining ===> #{@x_daylimit_remaining}")
		@x_daylimit = response.header("x_ratelimit_day_limit")
		@x_ratelimit = response.header("x_ratelimit_limit")
		@x_ratelimit_remaining = response.header("x_ratelimit_remaining")
		@x_ratelimit_reset = response.header("x_ratelimit_reset")
		@lastupdtime = Time.now.to_i
		ZohoCRMClient.debug_log("Inside update_apilimits_HTTPRESPONSE ===> #{self}")
=end
	end

	def get_lastupdtime
		return @lastupdtime
	end

	def getsleeptime
		result = 0
		time_now = ZohoCRMClient.getcurtimeinmillis
		if @x_daylimit_remaining.to_i < 1 then
			ZohoCRMClient.debug_log("Day limit remaining ===> #{@x_daylimit_remaining}")
			raise DayLimitExceeded.new(@lastupdtime)
		end
		if @x_ratelimit_reset.to_i > time_now then
			if @x_ratelimit_remaining.to_i > 0 then
				result = 0
			else
				result = @x_ratelimit_reset.to_i - time_now
				result = (result/1000).to_i + 1
			end
		end
		return result
	end
end

class InvalidTokensError < StandardError
	def initialize(msg = "Refresh_token is not valid. Please modify the ZohoCRMClient object or create a new ZohoCRMClient object to accomodate a current and valid refresh_token to proceed further.")
		super
	end
end
class DayLimitExceeded < StandardError
	def initialize(lastupdtime, msg = "Api limit remaining for today is zero. Please restart when api limit is refreshed.")
		@message = msg
		@lastupdtime = lastupdtime
	end
end
class APILimitsError < StandardError
	def initialze(msg = "Problem Occurred while fetching api limits")
		super
	end
end
class TestDataException < StandardError
	def initialize(msg = "Problem occurred while getting testing data ")
		super
	end
end
class BadRequestException < StandardError
	def initialize(msg = "Bad request")
		super
	end
end