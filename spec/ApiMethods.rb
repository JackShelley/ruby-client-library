require "spec_helper"
require "ZohoCRM_Client"

RSpec.describe ZCRMModule do
	before do
		@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a67dfebe56ae6bb8", "1000.7461b182dfddc8e94bf1ec3d9d770fdb.73dc7bb4ae2445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@apiObj = Api_Methods.new(zclient, "/Users/kamalkumar/ref_data1")
		@invalid_location = "/this/location/does/not/exist"
		@valid_location = "/Users/kamalkumar/spec_meta_folder/"
		@dummy_filename = "dummy.txt"
		@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9adfebe56ae6bb8", "1000.7461b182dfddc8e94bf1d9d770fdb.73dc7bb4ae2445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")

	end

	describe ".refresh_metadata" do
		context "meta_data available already" do
			it "should overwrite the files" do
				api = Api_Methods.new(@zclient)
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
				#Algo: (Read below two lines carefully)
				#if there is an auth error in the api, revoke token will be called
				#revoke token can mark if a token is bad.
				expect(false).to be_eq true
			end
		end
	end
end
