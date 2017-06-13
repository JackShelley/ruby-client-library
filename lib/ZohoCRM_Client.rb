require "ZohoCRM_Client/version"
require 'Constants'
require 'rest-client'
require 'time'



=begin
	Class name: ZohoCRMClient
	Member attributes: The necessary credentials for authenticating api calls
		1) Details associated with the client application created by the customer for authentication. 
		** Client secret
		** Client id
		** Redirect URI
			*** Client App name [These two are not so important. Not incorporated for now, will do if necessary]
			*** Client Domain
		2) Token details
		** Refresh token
		** Access token
		** Scope

	Member functions:
		_get
		_post
		_put
		_delete
=end

class ZohoCRMClient

	def initialize(client_id="", client_secret="", refresh_token="", access_token="", redirect_uri)
		@client_app = ClientAppDetails.new(client_id, client_secret, redirect_uri)
		if refresh_token.empty? then
			refresh_token = Constants::TOBEGENERATED
			access_token = Constants::TOBEGENERATED
		elsif access_token.empty? then
			access_token = Constants::TOBEGENERATED
		end
		@tokens = Tokens.new(refresh_token, access_token)
	end

	def set_tokens(refresh_token="", access_token="")
		if refresh_token.empty? then
			refresh_token = Constants::TOBEGENERATED
			access_token = Constants::TOBEGENERATED
		elsif access_token.empty? then
			access_token = Constants::TOBEGENERATED
		end
		@tokens.refresh_token = refresh_token
		@tokens.access_token = access_token
	end

	## Makes a HTTP::Get request to the URL along with given params, headers
	def _get(url="", params={}, headers={})
		if !params.empty? then
			headers[:params] = params
		end
		response = RestClient.get(url, headers)
		handle_response(response)
	end

	## Makes a HTTP::Post request to the URL along with given params, header and raw-content payload
	def _post(url="", params={}, headers={})#, payload="")
		print "\n"
		print "Inside _post ::::: "
		print url,"\n"
		print params,"\n"
		print headers,"\n"
		#if !params.empty? then
		#	headers[:params] = params
		#end
		begin
			response = RestClient.post(url, params, headers)
		rescue Exception => e
			puts "Exception in _post function :: Printing stack trace ::"
			puts e.message
			puts e.backtrace.inspect
			raise e
		end
		handle_response(response)
	end

	## Special handling if the API params involve a multipart payload::: For Upload attachment | photo API
	def _post_multipart(url="", params={}, headers={}, multipart_file="")
		begin
			f = File.new(multipart_file, 'rb')
		rescue Exception => e  ##{TODO: This message will be caught and directed to the user. For now, I am printing it here, since we do not have full structure for the gem}
			puts "Error Occurred while opening the multipart payload. Please check the file url again. "
			puts e.message
			raise e
		end
		if !params.empty? then
			headers[:params] = params
		end
		response = RestClient.post url, {:file => File.new(multipart_file, 'rb'), multipart=>true}, headers
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

	## Makes a HTTP::Put request to the URL along with given params, header
	def _delete(url="", params={}, headers={})
		if !params.empty? then
			headers[:params] = params
		end
		response = RestClient.delete(url, payload, headers)
		handle_response(response)
	end

	def response_headers_process(response)
		headers = response.headers
		#Sample header as a map
		#{:server=>"ZGS", :date=>"Fri, 09 Jun 2017 23:49:16 GMT", :content_type=>"application/json;charset=utf-8", :transfer_encoding=>"chunked", :connection=>"keep-alive", :set_cookie=>["6726760df9=9acc8767d4965247a4e734f98ab92de0; Path=/", "crmcsr=460bab42-9eeb-4a13-be4e-91ccf25e1e00; Path=/; Secure"], :x_content_type_options=>"nosniff", :x_xss_protection=>"1", :pragma=>"no-cache", :cache_control=>"no-store, no-cache, must-revalidate, private", :expires=>"Thu, 01 Jan 1970 00:00:00 GMT", :x_frame_options=>"SAMEORIGIN", :clientversion=>"1149948", :content_disposition=>"attachment; filename=response.json", :x_accesstoken_reset=>"2017-06-09T17:48:48-07:00", :x_ratelimit_reset=>"1497052216747", :x_ratelimit_remaining=>"99", :x_ratelimit_day_limit=>"5000", :x_ratelimit_day_remaining=>"4997", :x_ratelimit_limit=>"100", :content_encoding=>"gzip", :vary=>"Accept-Encoding", :strict_transport_security=>"max-age=15768000"}

	end

	## Checks API response for success, Panics in case of errors
	def handle_response(response)
		code = response.code
		is_success = false
		if code >= 200 && code < 400 then
			puts "Success\n"
			is_success = true
		elsif code == 401 then
			if revoke_token
				puts "Renewed access_token in place. Please try again"
			else
				puts "Failure" << "\n" 
				panic "Access token refresh failed...\n"
			end
		else
			puts "Failure"
		end
		## Printing everything for debugging purpose ## Pl remove eventually 
		print code, "\n"
		print response.body, "\n"
		print response.headers, "\n"

		if !is_success then
			raise "API response failed with code ::: " + code.to_s + " "
		end
		return response
	end

	def is_accesstoken_valid
		res = false
		t = Time.new.to_i

		if @tokens.expiry_time_insec.nil? then
			revoke_token #TODO: We need to call another api to find out the expiry time ## Validate tokens
		end
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

	def construct_headers
		if !self.is_accesstoken_valid then
			panic "Invalid token ::: Refresh_Token"
		end
		headers = {}
		auth_str = 'Zoho-oauthtoken ' + @tokens.access_token
		headers[:Authorization] = auth_str 
		return headers
	end

	def revoke_token
		res = false
		revoketoken_path = "oauth/v2/token"
		url = Constants::DEF_ACCOUNTS_URL + revoketoken_path
		print "Refreshing token ::: ","\n"
		print url
		params = {}
		params[:client_id] = @client_app.client_id
		params[:client_secret] = @client_app.client_secret
		params[:grant_type] = 'refresh_token'
		params[:refresh_token] = @tokens.refresh_token
		headers = {}
		#headers[:params] = params
		cur_t = Time.new.to_i
		response = _post(url, params, headers)
		code = response.code
		if code == 200 then
			json = response.body
			res_hash = JSON.parse(json)
			access_token = res_hash['access_token']
			exp_in_sec = res_hash['expires_in_sec']
			api_domain = res_hash['api_domain'] ##Do We need this? Im not sure, if we need it we can use it later
			exp_time = cur_t + exp_in_sec
			@tokens.expiry_time_insec = exp_time
			@tokens.access_token = access_token
			@tokens.is_refreshtoken_valid = true
			res = true
		else
			puts "Problem revoking token ::: refresh_token is in valid"
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
		@expiry_time_insec = nil
		@is_refreshtoken_valid = nil
	end
end

## API Limits, (daily and window limits)
## We will be checking limits before api calls, to avoid unnessary failed calls
class APILimits
	attr_accessor :x_daylimit_remaining, :x_daylimit, :x_ratelimit, :x_ratelimit_remaining, :x_ratelimit_reset
end