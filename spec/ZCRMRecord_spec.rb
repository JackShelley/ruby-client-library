require 'ZohoCRM_Client'

RSpec.describe ZCRMRecord do
	def load_modulelist_from_db(fp=@module_list_file)
		obj = Meta_data::load_yaml(fp)
		return obj
	end
	def save_modulelist_from_db(obj, fp=@module_list_file)
		Meta_data::dump_yaml(obj, fp)
	end
	before do
		#@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.4749c84f5218c90b92cb0795cd6d4aae.a4d2228eb017a7bfc265a0556a933f62", "1000.d25898a302dd992fba6521d678d429db.0a25fd3af864dc8b8549f854c65482e0", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@default_meta_folder = "/Users/kamalkumar/spec_meta_folder/"
		@conf_file = "/Users/kamalkumar/conf/config.yaml"
		@zclient, @apiObj = ZohoCRMClient.get_client_objects(@conf_file)
		#@apiObj = Api_Methods.new(@zclient, @default_meta_folder)
		#@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a6asdvsdebe56ae6bb8", "1000.7461b182dfddc8e94bf1ec3d9d770fdb.73dc7bb4aedsvsdvsd445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@lObj = @apiObj.load_crm_module("Leads")
		@leads_hv = @lObj.get_hash_values
		@invalid_folder = "/this/folder/does/not/exist"
		@module_list_file = "/Users/kamalkumar/spec_meta_folder/module_list"
		#@module_list = Meta_data.get_module_list(@zclient, true)
		#save_modulelist_from_db(@module_list, @module_list_file)
		@leads_fields = @lObj.get_fields
		@modules_map = load_modulelist_from_db(@module_list_file)
		@modules_map.delete("Activities")
		@module_list = load_modulelist_from_db(@module_list_file)
		@module_list.delete("Activities")
		@image_file = "/Users/kamalkumar/Downloads/osho001.jpg"
		@x_mod_list = ["Activities", "Tasks", "Events", "Calls", "Purchase_Orders", "Notes", "Quotes", "Invoices", "Sales_Orders", "Attachments", "Price_Books", "Approvals"] #, "Travels"]
		@x_data_type = ["autonumber"]
		@all_field_x_mod_list = ["Activities", "Tasks", "Events", "Calls", "Purchase_Orders", "Notes", "Quotes", "Invoices", "Sales_Orders", "Attachments", "Price_Books", "Potentials", "Deals", "Approvals"]
		@file_location = "/Users/kamalkumar/Downloads/attachment.pdf"
		@invalid_location = "/this/path/does/not/exist"
		@moduleVsrecord_id = {} #All these records have attachment
		#["Activities", "Tasks", "Events", "Calls", "Accounts", "Contacts", "Campaigns", "Leads", "Deals", "Purchase_Orders", "Notes", "Products", "Quotes", "Solutions", "Price_Books", "Invoices", "Sales_Orders", "Vendors", "Travels", "NewModules", "Entermodules", "Plural_form_of_module_nam", "Cases", "Attachments", "Approvals"]
		@attachment_x_list = ["Activities", "Calls", "Attachments", "Approvals"]
		@notes_x_list = ["Activities", "Notes", "Attachments", "Approvals"]
		@rel_mod_x_list = ["Invitees", "Expedia", "Notes", "Attachments"]
		@delink_supported = ["Leads", "Accounts", "Contacts", "Potentials", "Price Books"]

	end

	describe ".get_attachments" do
		context "module_obj is not set" do
			it "should return false and empty hash" do
				list = @module_list.keys
				list.each do |mod|
					#new_record = ZCRMRecord.new(self.module_name, {}, fields, self)
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					new_record = ZCRMRecord.new(mod, {}, fields, nil)
					bool, result = new_record.get_attachments
					expect(bool).to eq false
					expect(result).not_to be_nil
					expect(result).to be_empty
				end
			end
		end
		context "when record id is not set" do
			it "should return false and empty hash" do
				#new_record = ZCRMRecord.new(self.module_name, {}, fields, self)
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					bool, result = new_record.get_attachments
					expect(bool).to eq false
					expect(result).not_to be_nil
					expect(result).to be_empty
				end
			end
		end
		context "the record does not have any attachment" do
			it "should return true and empty hash" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					req_fields = mod_obj.get_required_fields
					all_fields = mod_obj.get_fields
					req_fields.each do |f_id|
						f_obj = all_fields[f_id] 
						f_name = f_obj.field_name
						datatype = f_obj.data_type
						value = nil
						if f_name != "Layout" then
							value = ZCRMField.get_test_data(f_obj, @apiObj)
						else
							value = new_record.layout_id
						end
						if datatype != "ownerlookup" then
							bool,message = new_record.set(f_obj, value)
							if !bool then
								ZohoCRMClient.debug_log("Field_name, field_id, datatype ==> #{f_name}, #{f_obj.field_id} , #{datatype} \n 
									Message ==> #{message}")
							end
							expect(bool).to eq true
						else
							bool, message = new_record.set_owner(f_obj, field_name)
							if !bool then
								ZohoCRMClient.debug_log("Problem occurred while setting owner, Error message ==> #{message}")
							end
							expect(bool).to eq true
						end
					end
					records = [new_record]
					output_arr = mod_obj.upsert(records)
					expect(output_arr[0]).to eq true
					expect(output_arr[1]).to eq Constants::GENERAL_SUCCESS_MESSAGE
					expect(output_arr[2]).not_to be_nil
					expect(output_arr[2]).not_to be_empty
					ZohoCRMClient.debug_log("The created id ==> #{output_arr[2]}")
					record_id = output_arr[2]
					record_id = record_id[0]
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool, result = r_obj.get_attachments
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).to be_empty
				end
			end
		end
		context "for all modules when there is an attachment" do
			it "should return true and a hash containing attachment_id and attachment_obj" do
				x_list = ["Activities", "Calls", "Attachments", "Approvals"]
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include? (mod) then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.upload_attachment(@file_location)
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).not_to be_empty

					bool, result = r_obj.get_attachments
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).not_to be_empty
					expect(result).to be_instance_of(Hash)
				end
			end
		end
	end #describe get_attachments

	describe ".upload_attachment" do
		context "module_obj is not set" do
			it "should return false and nil" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					new_record = ZCRMRecord.new(mod, {}, fields, nil)
					bool, result = new_record.upload_attachment(@file_location)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "when record id is not set" do
			it "should return false and nil" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					bool, result = new_record.upload_attachment(@file_location)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "The file location is invalid " do
			it "should return false and nil" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.upload_attachment(@invalid_location)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "file_type is nil or empty" do
			it "should return false and nil" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.upload_attachment(@file_location, nil)
					expect(bool).to eq false 
					expect(result).to be_nil
					bool, result = r_obj.upload_attachment(@file_location, "")
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "proper file location is given for a valid record " do
			it "should return true and attachment_id" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					ZohoCRMClient.debug_log("Trying for Module ==> #{mod} ")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.upload_attachment(@file_location, "image/pdf")
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).not_to be_empty
				end
			end
		end
	end #describe "upload attachment"

	describe ".download_attachment" do
		context "module_obj is not set" do
			it "should return false and nil" do
				list = @module_list.keys
				attachment_id = "1231423545"
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					new_record = ZCRMRecord.new(mod, {}, fields, nil)
					bool, result = new_record.download_attachment(attachment_id)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "when record id is not set" do
			it "should return false and nil" do
				#new_record = ZCRMRecord.new(self.module_name, {}, fields, self)
				list = @module_list.keys
				attachment_id = "1231423545"
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					bool, result = new_record.download_attachment(attachment_id)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "attachment id is nil or empty" do
			it "should return false and nil" do
				list = @module_list.keys
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.download_attachment(nil)
					expect(bool).to eq false
					expect(result).to be_nil
					bool, result = r_obj.download_attachment("")
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "attachment id is invalid " do
			it "should return false and nil" do
				list = @module_list.keys
				invalid_attachment_id = "2241234567"
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.download_attachment(invalid_attachment_id) 
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "attachment id is valid" do
			it "should return true and the file name" do
				list = @module_list.keys 
				list.each do |mod|
					if @attachment_x_list.include?(mod) then
						next
					end
					if @x_mod_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id = nil
					r_obj = nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					temp, attachments = r_obj.get_attachments
					a_id = nil
					if temp && !attachments.empty? then
						a_id = attachments.keys[0]
					else
						temp, a_id = r_obj.upload_attachment(@file_location)
					end
					bool, result = r_obj.download_attachment(a_id)
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).not_to be_empty
				end
			end
		end
	end #describe ".download_attachment"

	describe "upload_photo" do
		context "module object not set" do
			it "returns false" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool = r_obj.upload_photo(@image_file)
					expect(bool).to eq false
				end
			end
		end
		context "record_id is nil" do
			it "returns false" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool = r_obj.upload_photo(@image_file)
					expect(bool).to eq false
				end
			end
		end
		context "invalid image path" do
			it "returns false" do
				mod = "Leads"
				mod_obj = @apiObj.load_crm_module(mod)
				record_hash = mod_obj.get_records(1)
				r_id, r_obj = nil, nil
				record_hash.each do |i, r|
					r_id = i
					r_obj = r
				end
				bool = r_obj.upload_photo("")
				expect(bool).to eq false


				mod = "Contacts"
				mod_obj = @apiObj.load_crm_module(mod)
				record_hash = mod_obj.get_records(1)
				r_id, r_obj = nil, nil
				record_hash.each do |i, r|
					r_id = i
					r_obj = r
				end
				bool = r_obj.upload_photo("")
				expect(bool).to eq false

			end
		end
		context "invalid type " do
			it "returns false" do
				mod = "Leads"
				mod_obj = @apiObj.load_crm_module(mod)
				record_hash = mod_obj.get_records(1)
				r_id, r_obj = nil, nil
				record_hash.each do |i, r|
					r_id = i
					r_obj = r
				end
				bool = r_obj.upload_photo(@image_file, "")
				expect(bool).to eq false


				mod = "Contacts"
				mod_obj = @apiObj.load_crm_module(mod)
				record_hash = mod_obj.get_records(1)
				r_id, r_obj = nil, nil
				record_hash.each do |i, r|
					r_id = i
					r_obj = r
				end
				bool = r_obj.upload_photo(@image_file, "")
				expect(bool).to eq false
			end
		end
		context "invalid module" do
			it "returns false" do
				list = @module_list.keys
				x_list = ["Leads", "Contacts"]
				record_id = "2345678"
				list.each do |mod|
					if x_list.include? mod then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.upload_photo(@image_file)
					expect(bool).to eq false
				end
			end
		end
		context "invalid image file " do
			it "returns false" do
				list = ["Leads", "Contacts"]
				record_id = "2345678"
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.upload_photo(@invalid_location)
					expect(bool).to eq false
				end
			end
		end
		context "Valid image file and valid record " do
			it "returns true" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool = r_obj.upload_photo(@image_file)
					expect(bool).to eq true
				end
			end
		end
	end #describe "upload_photo"

	describe ".download_photo" do
		context "module object not set" do
			it "returns false" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool = r_obj.download_photo
					expect(bool).to eq false
				end
			end
		end
		context "record_id is nil" do
			it "returns false" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool = r_obj.download_photo
					expect(bool).to eq false
				end
			end
		end
		context "invalid module" do
			it "returns false" do
				x_list = ["Leads", "Contacts"]
				list = @module_list.keys
				record_id = "1234567"
				list.each do |mod|
					if x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.download_photo
					expect(bool).to eq false
				end
			end
		end
		context "invalid record_id" do
			it "returns false" do
				list = ["Leads", "Contacts"]
				record_id = "1234567"
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.download_photo
					expect(bool).to eq false

=begin
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
=end

				end
			end
		end
		context "record does not have a photo " do
			it "returns true and nil" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					req_fields = mod_obj.get_required_fields
					all_fields = mod_obj.get_fields
					req_fields.each do |f_id|
						f_obj = all_fields[f_id] 
						f_name = f_obj.field_name
						datatype = f_obj.data_type
						value = nil
						if f_name != "Layout" then
							value = ZCRMField.get_test_data(f_obj, @apiObj)
						else
							value = new_record.layout_id
						end
						if datatype != "ownerlookup" then
							bool,message = new_record.set(f_obj, value)
							if !bool then
								ZohoCRMClient.debug_log("Field_name, field_id, datatype ==> #{f_name}, #{f_obj.field_id} , #{datatype} \n 
									Message ==> #{message}")
							end
							expect(bool).to eq true
						else
							bool, message = new_record.set_owner(f_obj, field_name)
							if !bool then
								ZohoCRMClient.debug_log("Problem occurred while setting owner, Error message ==> #{message}")
							end
							expect(bool).to eq true
						end
					end
					records = [new_record]
					output_arr = mod_obj.upsert(records)
					expect(output_arr[0]).to eq true
					expect(output_arr[1]).to eq Constants::GENERAL_SUCCESS_MESSAGE
					expect(output_arr[2]).not_to be_nil
					expect(output_arr[2]).not_to be_empty
					ZohoCRMClient.debug_log("The created id ==> #{output_arr[2]}")
					record_id = output_arr[2]
					record_id = record_id[0]
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool, result = r_obj.download_photo
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).to be_empty
				end
			end
		end
		context "Record has a photo" do
			it "returns true, file_name" do
				list = ["Leads", "Contacts"]
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool = r_obj.upload_photo(@image_file)
					expect(bool).to eq true
					bool, file = r_obj.download_photo
					expect(bool).to eq true
					expect(file).not_to be_nil
					expect(file).not_to be_empty
					expect(File.exists?(file)).to eq true #todo check this
				end
			end
		end
	end #describe "download_photo"

	describe ".get_notes" do
		context "Module obj is not set" do
			it "returns false and empty hash" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool, result = r_obj.get_notes
					expect(bool).to eq false
					expect(result).to be_instance_of(Hash)
					expect(result).to be_empty

				end
			end
		end
		context "Record id is nil" do
			it "returns false and empty hash" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool, result = r_obj.get_notes
					expect(bool).to eq false
					expect(result).to be_instance_of(Hash)
					expect(result).to be_empty
				end
			end
		end
		context "invalid record id available" do
			it "returns false and empty hash" do
				list = @module_list.keys
				invalid_id = "12345567"
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(invalid_id)
					bool, result = r_obj.get_notes
					expect(bool).to eq false
					expect(result).to be_empty
				end
			end
		end
		context "No notes available" do
			it "returns true and empty hash" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include?(mod) then
						next
					end
					if (mod == "Contacts" || mod == "Leads") then
						next
					end						
					ZohoCRMClient.debug_log("Trying for ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					new_record = mod_obj.get_new_record
					req_fields = new_record.get_required_fields
					all_fields = mod_obj.get_fields
					req_fields.each do |f_id|
						f_obj = all_fields[f_id] 
						f_name = f_obj.field_name
						datatype = f_obj.data_type
						value = nil
						if f_name != "Layout" then
							value = ZCRMField.get_test_data(f_obj, @apiObj)
						else
							value = new_record.layout_id
						end
						if datatype != "ownerlookup" then
							bool,message = new_record.set(f_obj, value)
							if !bool then
								ZohoCRMClient.debug_log("Field_name, field_id, datatype ==> #{f_name}, #{f_obj.field_id} , #{datatype} \n 
									Message ==> #{message}")
							end
							expect(bool).to eq true
						else
							bool, message = new_record.set_owner(f_obj, field_name)
							if !bool then
								ZohoCRMClient.debug_log("Problem occurred while setting owner, Error message ==> #{message}")
							end
							expect(bool).to eq true
						end
					end
					records = [new_record]
					output_arr = mod_obj.upsert(records)
					expect(output_arr[0]).to eq true
					expect(output_arr[1]).to eq Constants::GENERAL_SUCCESS_MESSAGE
					expect(output_arr[2]).not_to be_nil
					expect(output_arr[2]).not_to be_empty
					ZohoCRMClient.debug_log("The created id ==> #{output_arr[2]}")
					record_id = output_arr[2]
					record_id = record_id[0]
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool, result = r_obj.get_notes
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).to be_empty
				end
			end
		end
		context "Notes are present" do
			it "should return true and a hash containing note_id vs note_obj" do
				list = @module_list.keys
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					if @x_mod_list.include?(mod) then
						next
					end
					if mod == "Leads" || mod == "Contacts" then
						next
					end
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, result = r_obj.create_note("Note title", "Note Content")
					expect(bool).to eq true
					bool, result = r_obj.get_notes
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).not_to be_empty
					n_id, n_obj = nil, nil
					result.each do |i, n|
						n_id = i
						n_obj = n
						expect(n_id).not_to be_nil
						expect(n_id).not_to be_empty
						expect(n_obj).not_to be_nil
						expect(n_obj).to be_instance_of(ZCRMNote)
					end
				end
			end
		end
	end #describe ".get_notes"

	describe ".create_note" do
		note_title = "Note Title"
		note_content = "Note Content"
		context "Module object not set" do
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					if mod == "Leads" || mod == "Contacts" then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool = r_obj.create_note(note_title, note_content)
					#Expectations
					expect(bool).to eq false
				end
			end
		end
		context "Record id is nil" do
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool = r_obj.create_note(note_title, note_content)
					expect(bool).to eq false
				end
			end
		end
		context "Note content is invalid" do
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					if @notes_x_list.include? (mod) then
						next
					end
					if @x_mod_list.include? (mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool = r_obj.create_note(note_title, nil)
					expect(bool).to eq false
					bool = r_obj.create_note(note_title, "")
					expect(bool).to eq false
				end
			end
		end
		context "Invalid record id " do
			it "should return false" do
				list = @module_list.keys
				record_id = "1234567"
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					if mod == "Leads" || mod == "Contacts" then
						next
					end
					ZohoCRMClient.debug_log("Trying for ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool, result = r_obj.create_note(note_title, note_content)
					expect(bool).to eq false
					expect(result).to be_nil
				end
			end
		end
		context "For all modules, with valid note content and a valid record" do
			it "should return true and Hash containing note_id vs note_obj" do
				list = @module_list.keys
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					if mod == "Leads" || mod == "Contacts" then
						next
					end
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, id = r_obj.create_note(note_title, note_content)
					expect(bool).to eq true
					expect(id).not_to be_nil
					expect(id).not_to be_empty
					expect(id).not_to be_instance_of(Hash)
				end
			end
		end
	end #describe ".create_note"

	describe ".update_notes" do
		note_title = "Updated Note Title"
		note_content = "Updated Note Content"
		dummy_hash = {}
		dummy_hash["12345678"] = ZCRMNote.new
		context "Module object not set" do
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool = r_obj.update_notes(dummy_hash)
					#Expectations
					expect(bool).to eq false
				end
			end
		end
		context "Record id is nil" do
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool = r_obj.update_notes(dummy_hash)
					expect(bool).to eq false
				end
			end
		end
		context "Notes hash is nil or empty" do
			record_id = "12345563643"
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.update_notes(nil)
					expect(bool).to eq false

					bool = r_obj.update_notes({})
					expect(bool).to eq false
				end
			end
		end
=begin
		context "Record id is invalid" do
			record_id = "123456789"
			it "should return false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id(record_id)
					bool = r_obj.update_notes(dummy_hash)
					expect(bool).to eq false
				end
			end
		end
=end
		context "Inputs are valid " do
			it "should return true, success_ids and failed_ids" do
				list = @module_list.keys
				list.each do |mod|
					if @notes_x_list.include?(mod) then
						next
					end
					if mod == "Leads" || mod == "Contacts" then
						next
					end
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					bool, notes = r_obj.get_notes
					expect(bool).to eq true
					if notes.empty? then
						temp_bool, temp_id = r_obj.create_note("Note Title", "Note content")
						expect(temp_bool).to eq true
						bool, notes = r_obj.get_notes
						expect(bool).to eq true
						expect(notes).not_to be_empty
					end
					sent_ids = []
					ZohoCRMClient.debug_log("Number of notes fetched for the record ==> #{notes.size}")
					notes.each do |n_id, note|
						note.update_title("Updated Note Title")
						note.update_content("Updated Note Content")
						sent_ids[sent_ids.length] = n_id
					end
					ZohoCRMClient.debug_log("Sent ids ==> #{sent_ids}")
					bool, s_ids, f_ids = r_obj.update_notes(notes)
					ZohoCRMClient.debug_log("Received success_ids ==> #{s_ids}")
					ZohoCRMClient.debug_log("Received failed_ids ==> #{f_ids}")
					expect(bool).to eq true
					s_ids.should =~ sent_ids
					expect(f_ids).to be_empty
				end
			end
		end
	end
	describe ".get_related_records" do 
		context "Module object is not nil" do
			it "returns false and an empty hash" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool, result = r_obj.get_related_records("Notes")
					expect(bool).to eq false
					expect(result).not_to be nil
					expect(result).to be_empty
					expect(result).to be_instance_of(Hash)
				end
			end
		end
		context "Record id is nil" do
			it "returns false and an empty hash" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool, result = r_obj.get_related_records("Notes")
					expect(bool).to eq false
					expect(result).not_to be nil
					expect(result).to be_empty
					expect(result).to be_instance_of(Hash)
				end
			end
		end
		context "Invalid related list api name given" do
			it "returns false and an empty hash" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					invalid_rel_name = "Invalid_related_module"
					bool, result = r_obj.get_related_records(invalid_rel_name)
					expect(bool).to eq false
					expect(result).not_to be nil
					expect(result).to be_empty
					expect(result).to be_instance_of(Hash)
				end
			end
		end
		context "record does not have the particular related record" do
			it "returns true and an empty hash" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include?(mod) then
						next
					end
					ZohoCRMClient.debug_log("Trying for ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					related_modules = mod_obj.get_related_modules
					if related_modules.empty? then
						ZohoCRMClient.debug_log("Related modules not available for ==> #{mod} ")
						next
					end
					expect(related_modules).not_to be_nil
					expect(related_modules).not_to be_empty
					record_hash = mod_obj.get_records(1)
					r_id, r_obj = nil, nil
					record_hash.each do |i, r|
						r_id = i
						r_obj = r
					end
					related_modules.each do |rel_mod|
						if @rel_mod_x_list.include?(rel_mod) then
							next
						end
						bool, result = r_obj.get_related_records(rel_mod)
						if !bool then
							ZohoCRMClient.debug_log("False returned for Related module ==> #{rel_mod}")
							next
						end
						expect(bool).to eq true
						if result.size > 0 then
							result.each do |temp_id, temp_obj|
								expect(temp_id).not_to be_nil
								expect(temp_id).not_to be_empty
								expect(temp_obj).not_to be_nil
								expect(temp_obj).to be_instance_of(ZCRMRecord)
							end
						end
					end
				end
			end
		end

	end #describe ".get_related_records"

	describe "update_related_record" do
		context "Module object is not set" do
			it "returns false" do
				expect(true).to eq true
			end
		end
	end

=begin
	describe ".delink_rl" do
		context "Module object is not set " do
			it "returns false " do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					fields = mod_obj.get_fields
					r_obj = ZCRMRecord.new(mod, {}, fields, nil)
					bool = r_obj.delink_rl("Campaigns", "12345678")
					expect(bool).to eq false
				end
			end
		end
		context "Record id is nil" do
			it "returns false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					bool = r_obj.delink_rl("Campaigns", "12345678")
					expect(bool).to eq false
				end
			end
		end
		context "Unsupported related modules" do
			it "returns false" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id("12345678")
					bool = r_obj.delink_rl("Unsupported_Module", "12345678")
					expect(bool).to eq false
				end
			end
		end
		context "Unsupported module" do
			it "returns false " do
				list = @module_list.keys
				list.each do |mod|
					if @delink_supported.include?(mod) then
						next
					end
					mod_obj = @apiObj.load_crm_module(mod)
					r_obj = mod_obj.get_new_record
					r_obj.set_record_id("12345678")
					bool = r_obj.delink_rl("Campaigns", "12345678")
					expect(bool).to eq false
				end
			end
		end
		
	end
=end

end

































