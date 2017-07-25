require "ZohoCRM_Client"

RSpec.describe ZCRMModule do
	def load_modulelist_from_db(fp=@module_list_file)
		obj = Meta_data::load_yaml(fp)
		return obj
	end
	def save_modulelist_from_db(obj, fp=@module_list_file)
		Meta_data::dump_yaml(obj, fp)
	end
	before do
		@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.4749c84f5218c90b92cb0795cd6d4aae.a4d2228eb017a7bfc265a0556a933f62", "1000.d25898a302dd992fba6521d678d429db.0a25fd3af864dc8b8549f854c65482e0", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@default_meta_folder = "/Users/kamalkumar/spec_meta_folder/"
		@apiObj = Api_Methods.new(@zclient, @default_meta_folder)
		@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a6asdvsdebe56ae6bb8", "1000.7461b182dfddc8e94bf1ec3d9d770fdb.73dc7bb4aedsvsdvsd445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@lObj = @apiObj.load_crm_module("Leads")
		@leads_hv = @lObj.get_hash_values
		@invalid_folder = "/this/folder/does/not/exist"
		@module_list_file = "/Users/kamalkumar/spec_meta_folder/module_list"
		#@module_list = Meta_data.get_module_list(@zclient, true)
		#save_modulelist_from_db(@module_list, @module_list_file)
		@leads_fields = @lObj.get_fields
		@modules_map = load_modulelist_from_db(@module_list_file)
		@module_list = load_modulelist_from_db(@module_list_file)
		@x_mod_list = ["Activities", "Tasks", "Events", "Calls", "Purchase_Orders", "Notes", "Quotes", "Invoices", "Sales_Orders", "Attachments", "Price_Books", "Approvals"] #, "Travels"]
		@x_data_type = ["autonumber"]
		@all_field_x_mod_list = ["Activities", "Tasks", "Events", "Calls", "Purchase_Orders", "Notes", "Quotes", "Invoices", "Sales_Orders", "Attachments", "Price_Books", "Potentials", "Deals", "Approvals"]

	end



=begin

Module meta_data keys 

global_search_supported = boolean [says if search is supported for this module]
related_lists = jsonArray [array of related lists, basically just the module name and its id]
deletable = boolean
creatable = boolean
layouts = jsonArray [array of layouts]
	visible - boolean [is the layout visible]
	name - string [name of the layout]
	sections - jsonArray 
		display_label - string 
		sequence_number - integer
		column_count - integer [for section ]
		name - string [for section]
		fields - jsonArray
			sequence_number - Integer
			convert_mapping - What is this? Not going to be used may be 
			api_name - string
			default_value - [default value for the field, if any, else null]
			id
business_card_fields - Array of strings
modified_time - timestamp
plural_label - string
id - long
$properties - 
layouts - jsonArray [array of layouts]


#try running the test for all other modules except for Activities, tasks, events, calls

	# common meta_data keys for all entities - 
		Worst case we could give functions that just pick these values from the hash_values	
			created_time
			modified_by
			profiles
			id
			created_by

#Upsert anamolies
	datetime could be a problem, Im going to test it by making 'datetime' field of Deals as mandatory
	problem while creating purchase orders
		Do not know what values to send for product_details field
	Product_details field is available for 
			Purchase orders, Quotes, 

=end
	
	describe ".delete_record" do
		#This function will not be used mostly, because you can do the same functionality using delete_records
		
	end

	describe ".update_record" do
		context "record is nil", :focus => true do
			it "should return false, nil" do
				record = nil
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					bool, record = mod_obj.update_record(record)
					#Expectations
					expect(record).to be_nil
					expect(bool).to eq false
				end
			end
		end
		context "record is not of type ZCRMRecord" do
			it "should return false, nil" do
				record = "nil"
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					bool, record = mod_obj.update_record(record)
					#Expectations
					expect(bool).to eq false
					expect(record).to be_nil
				end
			end
		end
		context "Given record is an new empty record" do
			it "should return false, nil" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_new_record
					bool, record = mod_obj.update_record(record)
					#Expectations
					expect(bool).to eq false
					expect(record).to be_nil
				end
			end
		end
		context "Some required fields do not have value" do 
		#todo commentout: this case may not happen
			it "should return false, nil" do
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_records(1)
					req_fields = mod_obj.get_required_fields
					n_req = req_fields.size
					temp = n_req/2
					temp_nil_fields = temp.times.map{ rand(n_req) }
					temp_nil_fields.uniq!
					nil_field_objs = []
					all_fields = mod_obj.get_fields
					temp_nil_fields.each do |seq|
						temp_id = req_fields[seq]
						nil_field_objs[nil_field_objs.length] = all_fields[temp_id]
					end
					nil_field_ids = []
					nil_field_objs.each do |f_obj|
						f_name = f_obj.field_name
						ZohoCRMClient.debug_log("Field name ==> #{field_name}")
						hv = record.get_hash_values
						hv[f_name] = nil
						f_id = f_obj.field_id
						nil_field_ids[nil_field_ids.length] = f_id
					end
					bool, result = mod_obj.update_record(record)
					#Expectations
					expect(bool).to eq false
					expect(result).not_to be_nil
					expect(result).to be_instance_of(Array)
					result.should =~ nil_field_ids
				end
			end
		end
		context "valid update", :focus => true do
			it "should return true" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record_hash = mod_obj.get_records(1)
					record = nil
					id = nil
					record_hash.each do |i, r|
						record = r
						id = i
					end
					ZohoCRMClient.debug_log("For id ===> #{id} ")
					upd_f_size = rand(10)
					all_fields = mod_obj.get_fields
					temp_idxs = upd_f_size.times.map{rand(all_fields.length)}
					ZohoCRMClient.debug_log("Field idxs ===> #{temp_idxs}")
					all_field_ids = all_fields.keys
					temp_idxs.each do |idx|
						temp_id = all_field_ids[idx]
						field = all_fields[temp_id]
						f_name = field.field_name
						value = nil
						if f_name != "Layout" then
							value = ZCRMField.get_test_data(field, @apiObj)
						else
							value = record.layout_id
						end
						datatype = field.data_type
						if datatype != "ownerlookup" then
							record.set(field, value)
						else
							record.set_owner(value, @apiObj.load_user_data)
						end
					end
					bool, result = mod_obj.update_record(record)
					#Expectations
					expect(bool).to eq true
					expect(result).not_to be_nil
					expect(result).to be_instance_of(Hash)
					assert1 = result.has_key?("code")
					expect(assert1).to eq true
					code = result["code"]
					expect(code.downcase).to eq("success")
				end
			end
		end
	end #describe .update_record

	describe ".get_record" do
		context "id is nil" do
			it "should return nil" do
				id = nil
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_record(id)
					#expectations
					expect(record).to be_nil
				end
			end
		end
		context "id is empty" do
			it "should return nil" do
				id = ""
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_record(id)
					#Expectations
					expect(record).to be_nil
				end
			end
		end
		context "id is wrong" do
			#204 no content
			it "should return nil" do
				id = "23456789876545678"
				list = @module_list.keys
				list.each do |mod|
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_record(id)
					#Expectations
					expect(record).to be_nil
				end
			end
		end
		context "id is proper " do
			it "should return a valid ZCRMRecord" do
				x_list = ["Attachments", "Notes"]
				#expect(false).to be_eq(true)
				list = @module_list.keys
				list.each do |mod|
					if x_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					records = mod_obj.get_records(1)
					id = nil
					records.each do |i,r|
						id = i
					end
					result = mod_obj.get_record(id)
					expect(result).not_to be_nil
					expect(result).to be_instance_of(ZCRMRecord)
					expect(result.record_id).to eq(id)
				end
			end
		end
	end #describe .get_record

	describe ".delete_records" do
		context "ids is nil" do
			it "should return false, and an empty array" do
				ids = nil
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to eq(false)
					expect(o2).to be_empty
				end
			end
		end
		context "ids is empty" do
			it "should return false, and an empty array " do
				ids = []
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to eq(false)
					expect(o2).to be_empty
				end
			end
		end
		context "ids are wrong" do
			it "should return false, and array containing ids that failed" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					n_recs = 1 + rand(50)
					ZohoCRMClient.debug_log("Number of records ==> #{n_recs}")
					records = mod_obj.get_records(n_recs)
					records.each do |r_id, r_obj|
						temp = r_id.to_i + 100000000000
						ids[ids.length] = temp.to_s
					end
					o1, o2 = mod_obj.delete_records(ids)
					expect(o1).to eq(false)
					expect(o2).not_to be_empty
					o2.should =~ ids
				end
			end
		end
		context "ids are partially wrong" do
			it "should return false, and array containing ids that failed " do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					val_ids = []
					inv_ids = []
					n_vals = 10
					records = mod_obj.get_records(n_vals)
					records.each do |r_id, r_obj|
						val_ids[val_ids.length] = r_id
						temp = r_id.to_i + 100000000000
						inv_ids[inv_ids.length] = temp.to_s
					end
					ids = val_ids + inv_ids
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to eq false
					expect(o2).not_to be_nil
					expect(o2).not_to be_empty
					o2.should =~ inv_ids
				end
			end
		end
		context "multiple ids, all are valid ids" do
			it "should return true, and an empty signifying that there are no failures" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					n_vals = 10
					records = mod_obj.get_records(n_vals)
					records.each do |r_id, r_obj|
						ids[ids.length] = r_id
					end
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to eq true
					expect(o2).to be_instance_of(Array)
					expect(o2).to be_empty
				end
			end
		end
	end #describe delete_records

	describe ".upsert" do
		context "create a record and update the same record and check for the updated_values" do
			it "should create a record with the given values" do
				expect(false).to be_eq(true)
			end
			it "should update the same record with the given values" do
				expect(false).to be_eq(true)
			end
		end
		context "Records have to be updated and created records simultaneously" do
			it "should return true, Success message and ids of both updated and created records" do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for this module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					all_fields = mod_obj.get_fields
					n_fields_to_be_upd = 1 + rand(all_fields.length)
					records = []
					n_recs_upd = 1 + rand(50)
					n_recs_ins = 1 + rand(50)
					records_hash = mod_obj.get_records(n_recs_upd)
					n_recs_upd = records_hash.size
					ZohoCRMClient.debug_log("Number of records being updated ===> #{n_recs_upd}")
					req_fields = mod_obj.get_required_fields
					req_field_objs = []
					req_fields.each do |temp|
						req_field_objs[req_field_objs.length] = all_fields[temp]
					end
					upd_records = []
					records_hash.each do |r_id, r_obj|
						req_field_objs.each do |f_obj|
							f_name = f_obj.field_name
							datatype = f_obj.data_type
							if f_name != "Layout" then
								value = ZCRMField.get_test_data(f_obj, @apiObj)
							else
								value = r_obj.layout_id
							end
							if datatype != "ownerlookup" then
								bool, message = r_obj.set(f_obj, value)
								if !bool then
									ZohoCRMClient.debug_log("Field name, datatype, field_id ===> #{f_name}, #{datatype}, #{f_obj.field_id} \n 
										Message ===> #{message} ")
								end
								expect(bool).to eq true
							else
								bool, message = r.set_owner(value, @apiObj.load_user_data)
								if !bool then
									ZohoCRMClient.debug_log("Setting owner failed for record ==> #{r_id} \n
										Message ==> #{message}")
								end
								expect(bool).to eq true
							end
						end
						upd_records[upd_records.length] = r_obj
					end
					ins_records = []
					ZohoCRMClient.debug_log("Number of records being Inserted ===> #{n_recs_ins}")
					n_recs_ins.times do |i|
						r_obj = mod_obj.get_new_record
						req_field_objs.each do |f_obj|
							f_name = f_obj.field_name
							datatype = f_obj.data_type
							if f_name != "Layout" then
								value = ZCRMField.get_test_data(f_obj, @apiObj)
							else
								value = r_obj.layout_id
							end
							if datatype != "ownerlookup" then
								bool, message = r_obj.set(f_obj, value)
								if !bool then
									ZohoCRMClient.debug_log("Field name, datatype, field_id ===> #{f_name}, #{datatype}, #{f_obj.field_id} \n 
										Message ===> #{message} ")
								end
								expect(bool).to eq true
							else
								bool, message = r.set_owner(value, @apiObj.load_user_data)
								if !bool then
									ZohoCRMClient.debug_log("Setting owner failed for record ==> #{r_id} \n
										Message ==> #{message}")
								end
								expect(bool).to eq true
							end
						end
						ins_records[ins_records.length] = r_obj
					end
					records = upd_records + ins_records
					n_sent_recs = records.length
					ZohoCRMClient.debug_log("Number of sent records ==> #{n_sent_recs}")
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to eq(true)
					expect(o2).to eq(Constants::GENERAL_SUCCESS_MESSAGE)
					expect(o3.length).to eq(n_sent_recs)
				end
			end
		end
		context "records are empty" do
			it "should return false, record_empty message and an empty array" do
				records = []
				list = @module_list.keys 
				list.each do |mod|
					if mod == "Approvals" then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to eq(false)
					expect(o2).to eq(Constants::EMPTY_RECORDS_MSG)
					expect(o3).to be_empty
				end
			end
		end
		context "the records do not have all the required fields set" do
			it "returns false and error message " do
				list = @module_list.keys
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					all_fields = mod_obj.get_fields
					req_fields = mod_obj.get_required_fields
					#n_recs_per_page = 1 + rand(50)
					n_new_recs = 1 + rand(50)
					ZohoCRMClient.debug_log("Number of new records ===> #{n_new_recs}")
					n_inv_recs = n_new_recs/2
					ZohoCRMClient.debug_log("Number of invalid records ===> #{n_inv_recs}")
					inv_records = []
					n_inv_recs.times do |i|
						inv_r = mod_obj.get_new_record
						t_rand = rand(req_fields.length)
						tf_id = req_fields[t_rand]
						req_fields.each do |rf_id|
							if rf_id == tf_id then
								next
							end
							rf_obj = all_fields[rf_id]
							field_name = rf_obj.field_name
							if field_name != "Layout" then
								value = ZCRMField.get_test_data(rf_obj, @apiObj)
							else
								value = inv_r.layout_id
							end
							datatype = rf_obj.data_type
							if datatype != "ownerlookup" then
								bool, message = inv_r.set(rf_obj, value)
								if !bool then
									ZohoCRMClient.debug_log("Field name, datatype, id ==> #{field_name}, #{datatype}, #{rf_obj.field_id} \n 
									Message ==> #{message} \n")
								end
							else
								bool, message = inv_r.set_owner(value, @apiObj.load_user_data)
								if !bool then
									ZohoCRMClient.debug_log("Setting owner failed for record if ==> #{rf_obj.record_id} \n
										Message ==> #{message} \n")
								end
							end
						end
						inv_records[inv_records.length] = inv_r
					end
					n_val_recs = n_inv_recs
					val_records = []
					n_val_recs.times do |i|
						val_r = mod_obj.get_new_record
						req_fields.each do |rf_id|
							rf_obj = all_fields[rf_id]
							field_name = rf_obj.field_name
							if field_name != "Layout" then
								value = ZCRMField.get_test_data(rf_obj, @apiObj)
							else
								value = val_r.layout_id
							end
							datatype = rf_obj.data_type
							if datatype != "ownerlookup" then
								bool, message = val_r.set(rf_obj, value)
								if !bool then
									ZohoCRMClient.debug_log("Field name, datatype, id ==> #{field_name}, #{datatype}, #{rf_obj.field_id} \n 
									Message ==> #{message} \n")
								end
							else
								bool, message = val_r.set_owner(value, @apiObj.load_user_data)
								if !bool then
									ZohoCRMClient.debug_log("Setting owner failed for record if ==> #{rf_obj.record_id} \n
										Message ==> #{message} \n")
								end
							end
						end
						val_records[val_records.length] = val_r
					end
					records = val_records + inv_records
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to eq(false)
					expect(o2).to eq(Constants::MAND_FIELDS_NOT_SET)
					expect(o3.length).to eq(n_inv_recs) 
					#SUGGEST: #We can have a attribute for zcrmrecord called req_fields_not_set=[].
				end
			end
		end
	end #describe upsert
	describe ".update_records" do 
		#Anamolies
			# Call Status is a picklist but field metadata does not have picklist_values
		context "records is empty" do
			it "returns false and error message" do
				records = {}
				r1,r2 = @lObj.update_records(records)
				expect(r1).to eq(false)
				expect(r2).to be_instance_of(String)
				expect(r2).to eq(Constants::NO_RECORD_TO_UPDATE)
			end
		end
		context "records passed have not been updated" do
			it "returns success_ids and failed_ids, the records passed have not been updated!" do
				records = {}
				list = @module_list.keys
				#n_recs = 1 + rand(200)
				n_recs = 10
				ZohoCRMClient.debug_log("Number of recs ===> #{n_recs}")
				list.each do |mod|
					if @x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("trying for module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					if !mod_obj.is_editable then
						next
					end

					records = mod_obj.get_records(n_recs)
					record_ids = records.keys
					size = records.size
					h_size = size/2
					temp = h_size.times.map{rand(size)}
					not_updated_ids = []
					temp.each do |seq|
						temp_id = record_ids[seq]
						not_updated_ids[not_updated_ids.length] = temp_id
					end
					to_be_updated_fields = {}
					all_fields = mod_obj.get_fields
					all_fields_ids = all_fields.keys
					number_of_fields_to_update = 1 + rand(all_fields.length)
					to_update_f_seqs = number_of_fields_to_update.times.map{rand(all_fields.length)}
					to_update_f_seqs.uniq!
					to_update_f_seqs.each do |seq|
						to_be_updated_field_id = all_fields_ids[seq]
						to_be_updated_field_obj = all_fields[to_be_updated_field_id]
						to_be_updated_fields[to_be_updated_field_id] = to_be_updated_field_obj
					end
					records.each do |id, r|
						if not_updated_ids.include? id then
							next
						end
						#Update the id
						to_be_updated_fields.each do |f_id, field_obj|
							f_name = field_obj.field_name
							datatype = field_obj.data_type
							if f_name != "Layout" then
								value = ZCRMField.get_test_data(field_obj, @apiObj)
							else
								value = r.layout_id
							end
							#ZohoCRMClient.debug_log("Field name, datatype, value ===> #{f_name}, #{datatype}, #{value}")
							if datatype != "ownerlookup" then
								bool, message = r.set(field_obj, value)
								if !bool then
									next
								end
								#expect(bool).to eq true
							else
								temp, message = r.set_owner(value, @apiObj.load_user_data)
								expect(temp).to eq true
							end
						end
					end
					s_ids = record_ids - not_updated_ids
					f_ids = not_updated_ids
					ZohoCRMClient.debug_log("s_ids, f_ids ===> #{s_ids}, #{f_ids}")
					r_s_ids, r_f_ids = mod_obj.update_records(records)
					ZohoCRMClient.debug_log("r_s_ids, r_f_ids ===> #{r_s_ids}, #{r_f_ids}")
					#Assertions
					expect(r_s_ids).not_to be_nil
					expect(r_f_ids).not_to be_nil
					r_s_ids =~ s_ids
					r_f_ids =~ f_ids
				end
			end
		end
		context "all fields are being updated, for all the modules" do
			it "should return all the ids in success_ids and none in failure_ids" do
				#Anamolies - Deals - "Type" field name, gets set if we set another 
				list = @module_list.keys
				list.each do |mod|
					if @all_field_x_mod_list.include? mod then
						next
					end
					ZohoCRMClient.debug_log("Trying for module ===> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					#rand_per_page = 1 + rand(200)
					rand_per_page = 10
					records = mod_obj.get_records(rand_per_page)
					record_ids = records.keys
					all_fields = mod_obj.get_fields
					records.each do |r_id, record|
						all_fields.each do |f_id, f_obj|
							f_name = f_obj.field_name
							datatype = f_obj.data_type
							if @x_data_type.include?(datatype) then
								next
							end
							if f_name != "Layout" then
								value = ZCRMField.get_test_data(f_obj, @apiObj)
							else
								value = record.layout_id
							end
							if datatype != "ownerlookup" then
								bool, message = record.set(f_obj, value)
								if !bool then
									ZohoCRMClient.debug_log("Field_name, datatype, value ===> #{f_name}, #{datatype}, #{value}")
									ZohoCRMClient.debug_log("Error Message ===> #{message}")
									next
								end
								expect(bool).to eq true
							else
								temp, message = record.set_owner(value, @apiObj.load_user_data)
								if !temp then
									ZohoCRMClient.debug_log("Error setting owner id to ===> #{value}")
									ZohoCRMClient.debug_log("Error message ===> #{message}")
								end
								expect(temp).to eq true
							end
						end
					end
					s_ids, f_ids = mod_obj.update_records(records)
					#Assertions
					s_ids.should =~ record_ids
					expect(f_ids).to be_empty
				end
			end
		end
	end #describe .update_records

	describe ".get_records" do
		context "Wrong inputs" do
			context "per_page has invalid values" do
				it "should take the default value for per_page and get records according to other params" do
					per_page = ""
					fields = @lObj.get_fields
					ids = fields.keys
					n_fields = ids.length
					rand_num = 1 + rand(n_fields)
					a_field_id = ids[rand_num]
					a_field = fields[a_field_id]
					a_field_name = a_field.field_name
					b_field_id = ids[rand_num+1]
					b_field = fields[b_field_id]
					b_field_name = b_field.field_name
					ZohoCRMClient.debug_log("Printing a_field_name, b_field_name ===> #{a_field_name}, #{b_field_name}")
					temp_fields = []
					temp_fields[0] = a_field_name
					page = 1
					sort_order = "desc"
					ZohoCRMClient.debug_log("We are going to call get_records here ===> ")
					records = @lObj.get_records(per_page, temp_fields, page, sort_order)
					records.each do |record_id, record|
						val = record.get(a_field_name)
						hv = record.get_hash_values
						#new assertions
						expect(hv.has_key?(a_field_name)).to eq(true)
						expect(hv.has_key?(b_field_name)).to eq(false)
						#old assertions
						#ZohoCRMClient.debug_log("Printing record_id ====> #{record_id}")
						#ZohoCRMClient.debug_log("Printing the entire hash_values #{hv}")
						#expect(val).not_to be_nil
						#val = record.get(b_field_name)
						#expect(val).to be_nil
					end
				end
			end
			context "fields is invalid values" do
				it "should take default values for fields and get records according to other params" do
					per_page = 50
					fields = "Invalid_fields_value"
					page=1
					sort_order = ""
					records = @lObj.get_records(per_page, fields, page, sort_order)
					#Assertions
					expect(records).not_to be_nil
					expect(records.size).to eq(per_page)
				end
			end
			context "fields have invalid field names" do
				it "should return invalid field names" do
					invalid_fields = []
					count = 0
					inv_fields_count = 1 + rand(10)
					field_ids_arr = @leads_fields.keys
					loop do
						f_id = field_ids_arr[count]
						f_name = @leads_fields[f_id].field_name
						invalid_fields[invalid_fields.length] = f_name + "RANDOMTEXT"
						count = count+1
						break if count >= inv_fields_count
					end
					v_f_seq = 10.times.map{rand(field_ids_arr.length)}
					v_f_seq = v_f_seq.uniq
					v_fields = []

					v_f_seq.each do |f_seq|
						f_id = field_ids_arr[f_seq]
						f_name = @leads_fields[f_id].field_name
						v_fields[v_fields.length] = f_name
					end
					fields_param = v_fields + invalid_fields
					ZohoCRMClient.debug_log("The invalid fields that is passed is ===> #{invalid_fields}")
					ZohoCRMClient.debug_log("The valid fields that are passed ===> #{v_fields}")
					fields_param.shuffle!
					per_page = 30
					page = 1
					records = @lObj.get_records(per_page, fields_param, page)
					#Expectations
					expect(records).not_to be_nil
					expect(records).to be_instance_of(Array)
					invalid_fields.should =~ records
				end
			end
			context "page has invalid values" do
				it "should return records according to the other params " do
					per_page = 100
					field_ids_arr = @leads_fields.keys
					rand_num1 = rand(field_ids_arr.length)
					rand_num2 = rand(field_ids_arr.length)
					expect(rand_num2).not_to eq(rand_num1)
					a_field_id = field_ids_arr[rand_num1]
					b_field_id = field_ids_arr[rand_num2]
					a_field_obj = @leads_fields[a_field_id]
					b_field_obj = @leads_fields[b_field_id]
					a_field_name = a_field_obj.field_name
					b_field_name = b_field_obj.field_name
					fields = []
					fields[0] = a_field_name
					page = "Invalid entry "
					sort_order = ""
					records = @lObj.get_records(per_page, fields, page, sort_order)
					#Assertions
					expect(records).not_to be_nil
					expect(records).to be_instance_of(Hash)
					expect(records.size).to eq(100)
					records.each do |r_id, record|
						hv = record.get_hash_values
						expect(hv.has_key?(a_field_name)).to eq true
						expect(hv.has_key?(b_field_name)).to eq false
					end
				end
			end
			context "sort_order is invalid" do
				it "should return records according to the other params " do
					per_page = 100
					fields = []
					page = 1
					sort_order = "RANDOMTEXT"
					records = @lObj.get_records(per_page, fields, page, sort_order)
					#Assertions
					expect(records).not_to be_nil
					expect(records).to be_instance_of(Hash)
					expect(records.size).to eq(100)
				end
			end
		end
		#next context
		context "For all modules, get_records should return records according to the params" do
			# Decisions: 
			# Step 1. We need to get_records for 2 pages. 
			# Step 2. Repeat the same thing for a different sort
			# Step 3. Try setting approved=true 
			# Step 4. Try setting converted=false
			context "getting records modifying page numbers" do
				it "should return records according to the supplied page numbers" do
					#Things to expect for
					# The ids returned in the previous page should not be present in the current page
					# When we are getting records for asc sort_order store them in an array [We should preserve the order]
						#Then when we get records for desc sort_order we should store them in a diff array [preserving order]
						#We need to compare the two arrays asc_sort_order_ids and desc_sort_order_ids for equality
						#We need to see if the ids are desc_record_ids in the exact same order but reversed when compared with the asc_sort_ids
					list = @module_list.keys

					list.each do |module_name|
						ZohoCRMClient.debug_log("Checking for module ===> #{module_name}")
						mod_obj = @apiObj.load_crm_module(module_name)
						#ASC sort order
						page = 1
						asc_sort_ids = []
						asc_temp_ids = []
						n_recs_per_page = 1 + rand(200) #Generates random number from 0-199.
						#n_recs_per_page = 5
						ZohoCRMClient.debug_log("ASCENDING order ==> ")

						loop do
							asc_temp_ids.clear()
							records = mod_obj.get_records(n_recs_per_page, [], page, "asc")
							size = records.size
							records.each do |id, r_obj|
								asc_temp_ids[asc_temp_ids.length] = id
							end
							ZohoCRMClient.debug_log("Printing page ==> #{page}")
							ZohoCRMClient.debug_log("Printing asc_temp_ids ==> #{asc_temp_ids}")


							temp = asc_temp_ids - asc_sort_ids
							expect(temp.length).to eq(asc_temp_ids.length)
							temp.should =~ asc_temp_ids
							asc_sort_ids.concat(asc_temp_ids)
							ZohoCRMClient.debug_log("Printing asc_sort_ids ==> #{asc_sort_ids}")
							break if (size<n_recs_per_page || page > 2)
							page = page+1
						end

						ZohoCRMClient.debug_log("DESCENDING order ==> ")

						#DESC sort order
						page = 1
						desc_sort_ids = []
						desc_temp_ids = []
						loop do
							records = mod_obj.get_records(n_recs_per_page, [], page, "desc")
							size = records.size
							records.each do |id, r_obj|
								desc_temp_ids[desc_temp_ids.length] = id
							end
							ZohoCRMClient.debug_log("Priting page ==> ")
							temp = asc_temp_ids - asc_sort_ids
							expect(temp).to be_empty
							expect(temp.length).to eq(0)
							desc_sort_ids.concat(desc_temp_ids)
							break if (size<n_recs_per_page || page > 2)
							page = page+1
						end
					end

				end
			end
			context "For all modules, passing a list of fields along the params" do
				#Some tests fail, because some of the given fields are not returned
				it "should have only the fields passed along the params" do
					list = @module_list.keys
					list.each do |module_name|
						if @x_mod_list.include?(module_name) then
							next
						end
						ZohoCRMClient.debug_log("Trying for module ===> #{module_name}")
						url = Constants::DEF_CRMAPI_URL + module_name
						mod_obj = @apiObj.load_crm_module(module_name)
						fields = mod_obj.get_fields
						n_avail_fields = fields.length
						n_fields_to_send = 1 + rand(n_avail_fields)
						field_seq_arr = n_fields_to_send.times.map{rand(n_avail_fields)}
						field_seq_arr = field_seq_arr.uniq
						n_fields_to_send = field_seq_arr.size
						field_name_arr = []
						fields.each do |id, field|
							field_name_arr[field_name_arr.length] = field.field_name
						end
						fields_param = []
						field_seq_arr.each do |seq|
							fname = field_name_arr[seq]
							fields_param[fields_param.length] = fname
						end
						field_csv = fields_param.join(",")
						ZohoCRMClient.log("We are making a get_records call, with the following fields ")
						ZohoCRMClient.log(field_csv)
						ZohoCRMClient.log("number of fields ===> #{fields_param.length}")
						n_recs_per_page = 1 + rand(200)
						records = mod_obj.get_records(n_recs_per_page, fields_param)
						records.each do |id, record|
							record_hash = record.get_hash_values
							fields_returned = record_hash.keys
							if fields_returned.include? "id" then
								fields_returned.delete("id")
							end
							if fields_returned.include? "$editable" then
								fields_returned.delete("$editable")
							end
							ZohoCRMClient.debug_log("Fields returned ====> #{fields_returned}")
							expect(fields_returned.size).to eq(fields_param.size)
							fields_returned.should =~ fields_param
						end
					end
				end
			end
		end
	end #describe ".get_records" ends

	describe ".populate_required_fields" do
		context "Every module has required fields" do
			it "the marked required fields should be same as the one's from the Api's" do
				list = @module_list.keys
				list.each do |module_name|
					ZohoCRMClient.debug_log("For module ====> #{module_name}")
					url = Constants::DEF_CRMAPI_URL + "settings/modules/" + module_name
					ZohoCRMClient.debug_log("The url ===> #{url}")
					headers = @zclient.construct_headers
					params = {}
					response = @zclient.safe_get(url, params, headers)
					expect(response).not_to be_nil
					body = response.body
					json_list = Api_Methods._get_list(body, "modules")
					json = json_list[0]
					api_name = json['api_name']
					singular_label = json['singular_label']
					plural_label = json['plural_label']
					mod_obj = ZCRMModule.new(@zclient, json, @default_meta_folder, api_name, singular_label, plural_label)
					field_list = json["fields"]
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
						mod_obj.add_field(f)
					end
					mod_obj.populate_required_fields
					req_field_ids = mod_obj.required_fields_test
					#We are going to iterate the body, to find out manually what are the required fields
					#In other words we are going to our own required_fields and compare it with the req_field_ids
					#How do you form it?
					m_req_fields = []
					layouts = json['layouts']
					layouts.each do |layout_hash|
						sections = layout_hash["sections"]
						sections.each do |sections_hash|
							fields = sections_hash["fields"]
							fields.each do |field|
								required = field["required"]
								if required then
									field_id = field["id"]
									m_req_fields[m_req_fields.length] = field_id
								end
							end
						end
					end
					m_req_fields.should =~ req_field_ids
					fields = mod_obj.get_fields
					req_field_ids.each do |f_id|
						f_obj = fields[f_id]
						expect(f_obj.is_required).to eq true
					end
				end
			end
		end

	end #describe populate_required_fields

	#describe
	describe ".get_required_fields" do
		context "creating a new_record by only setting values for the required fields" do
			it "record should be created" do
				#Doing the same for all the modules
				list = @module_list.keys
				#x_mod_list = ["Activities", "Tasks", "Events", "Calls", "Purchase_Orders", "Notes", "Quotes", "Invoices", "Sales_Orders", "Attachments"]
				list.each do |module_name|
					if @x_mod_list.include?(module_name) then
						next
					end
					ZohoCRMClient.debug_log("Creating a record for module ===> #{module_name}")
					mod_obj = @apiObj.load_crm_module(module_name)
					if !mod_obj.is_creatable then
						next
					end
					record = mod_obj.get_new_record
					req_fields = mod_obj.get_required_fields
					fields = mod_obj.get_fields
=begin #For debugging purpose
					req_fields.each do |f_id|
						f_obj = fields[f_id]
						f_name = f_obj.field_name
						data_type = f_obj.data_type
						f_id = f_obj.field_id
						ZohoCRMClient.debug_log("Printing field_name, data_type, field_id ===> #{f_name} , #{data_type} , #{f_id} ")
					end
=end
					req_fields.each do |f_id|
						f_obj = fields[f_id]
						value = ZCRMField.get_test_data(f_obj, @apiObj)
						f_name = f_obj.field_name
						bool = record.set(f_obj, value)
						expect(bool).to eq true
					end

=begin
					fields.each do |id, field|
						if req_fields.include? id || field.is_required then
							data_type = field.data_type
							value = ZCRMField.get_test_data(data_type, @apiObj)
							field_name = field.field_name
							field.set(field_name, value)
						end
					end
=end

					records = []
					records[0] = record
					result = mod_obj.upsert(records) #returns an array of length 3
					#new assertions
					expect(result[0]).to eq true
					expect(result[1]).to eq Constants::GENERAL_SUCCESS_MESSAGE
					expect(result[2]).not_to be_nil
					expect(result[2]).to be_instance_of(Array)
					expect(result[2]).not_to be_empty

=begin
					#old Assertions
					expect(result[0]).not_to be_nil
					result.each do |id, r_obj|
						expect(id).not_to be_nil
						expect(r_obj).not_to be_nil
						expect(r_obj.module_name).to be_eq(module_name)
						expect(id).to be_eq(r_obj.record_id)
						expect(r_obj.class).to be_eq(ZCRMRecord) 
					end
=end

				end
			end
		end
	end #describe .get_required_fields



	describe ".get_new_record" do
		context "for every module we should end up with a ZCRMRecord object" do
			it "should return a new record for module_obj's module" do
				list = @module_list.keys
				list.each do |module_name|
					mod_obj = @apiObj.load_crm_module(module_name)
					if mod_obj.nil? then
						ZohoCRMClient.debug_log("Nil was returned for module => #{module_name}")
					end
					expect(mod_obj).not_to be_nil
					record = mod_obj.get_new_record
					expect(record).not_to be_nil
					expect(record).to be_instance_of(ZCRMRecord)
					expect(record.module_name).to eq(module_name)
				end
			end
		end
	end #describe .get_new_record

	describe "test_code" do
		context "Testing code by myself" do
			it "July 18 2017" do
				ZohoCRMClient.debug_log("Module_list ==> #{@module_list.keys}")
				list = @module_list.keys
				list.each do |mod|
					ZohoCRMClient.debug_log("Module ==> #{mod}")
					mod_obj = @apiObj.load_crm_module(mod)
					ZohoCRMClient.debug_log("Is Creatable ==> #{mod_obj.is_creatable} \n Is editable ==> #{mod_obj.is_editable} \n Is deletable ==> #{mod_obj.is_deletable} \n Is Viewable ==> #{mod_obj.is_viewable}")					
				end
			end
			it "June 13 2017" do
				ZohoCRMClient.debug_log("Printing default folder ===> #{@default_meta_folder}")
				ZohoCRMClient.debug_log("Getting meta data for leads alone ====> ")
				module_name = "Leads"
				res = Meta_data.module_data(@zclient, module_name, @default_meta_folder)
				expect(res).to eq true
			end
			it "should just pass things I put here" do
				api_sup_mods = []
				api_non_sup_mods = []
				createable_mods = []
				non_createable_mods = []
				editable_mods = []
				non_editable_mods = []
				viewable_mods = []
				non_viewable_mods = []
				deletable_mods = []
				non_deletable_mods = []

				@modules_map.each do |mod_name, mod_hash|
					mod_obj = @apiObj.load_crm_module(mod_name)
					api_supported = mod_hash['api_supported']
					if api_supported then
						api_sup_mods[api_sup_mods.length] = mod_name
					else
						api_non_sup_mods[api_non_sup_mods.length] = mod_name
					end
					if mod_obj.is_creatable then
						createable_mods[createable_mods.length] = mod_name
					else
						non_createable_mods[non_createable_mods.length] = mod_name
					end
					if mod_obj.is_viewable then
						viewable_mods[viewable_mods.length] = mod_name
					else
						non_viewable_mods[non_viewable_mods.length] = mod_name
					end
					if mod_obj.is_deletable then
						deletable_mods[deletable_mods.length] = mod_name
					else
						non_deletable_mods[non_deletable_mods.length] = mod_name
					end
				end
=begin
				print "Printing Api non supported modules ====> "
				ZohoCRMClient.debug_log(api_non_sup_mods)
				print "Printing Api supported modules ====> "
				ZohoCRMClient.debug_log(api_sup_mods)
				print "Printing Non-Creatable modules ====> "
				ZohoCRMClient.debug_log(non_createable_mods)
				print "Printing Creatable modules ====> "
				ZohoCRMClient.debug_log(createable_mods)
				print "Printing Non-Editable modules ====> "
				ZohoCRMClient.debug_log(non_editable_mods)
				print "Printing Editable modules ====> "
				ZohoCRMClient.debug_log(editable_mods)
				print "Printing Non-Viewable modules ====> "
				ZohoCRMClient.debug_log(non_viewable_mods)
				print "Printing Viewable modules ====> "
				ZohoCRMClient.debug_log(viewable_mods)
				print "Printing Non-Deletable modules ====> "
				ZohoCRMClient.debug_log(non_deletable_mods)
				print "Printing Deletable modules ====> "
				ZohoCRMClient.debug_log(deletable_mods)
=end
			end
		end
	end

=begin

	describe ".initialize" do
		#def initialize(zclient, api_name="", singular_label="", plural_label="", hash_values={}, meta_folder="")
		context "improper zclient" do
			it "should return nil " do
				tokens = @improper_zclient.get_tokens
				tokens.is_refreshtoken_valid = false
				result = ZCRMModule.new(@improper_zclient, @leads_hv, @default_meta_folder)
				expect(result).to be_nil
			end
		end
		context "invalid api_name" do
			it "should populate it from hash_values, it should return nil if problem occur" do
				result = ZCRMModule.new(@zclient, @leads_hv, @default_meta_folder)
				expect(result).not_to be_nil
				expect(result.class.public_instance_methods.include? :get_records).to be_eq true
				api_name = @leads_hv["api_name"]
				expect(result.module_name).not_to be_nil
				expect(result.module_name).to be_eq(api_name)
			end
		end
		context "invalid singular_label" do
			it "should populate from hash_values, should return nil if problem occur" do
				result = ZCRMModule.new(@zclient, @leads_hv, @default_meta_folder)
				expect(result).not_to be_nil
				expect(result.class.public_instance_methods.include? :get_records).to be_eq true
				s_label = @leads_hv["singular_label"]
				expect(result.singular_label).to be_eq(s_label)
			end
		end
		context "invalid plural_name" do
			it "should populate from hash_values, should return nil if problem occur" do
				result = ZCRMModule.new(@zclient, @leads_hv, @default_meta_folder)
				expect(result).not_to be_nil
				expect(result.class.public_instance_methods.include? :get_records).to be_eq true
				p_label = @leads_hv["plural_label"]
				expect(result.plural_label).to be_eq(p_label)
			end
		end
		context "invalid hash_values" do
			context "it is nil" do
				it "should return nil" do
					hv = nil
					result = ZCRMModule.new(@zclient,hv,@default_meta_folder)
					expect(result).to be_nil
				end
			end
			context "it is empty" do
				it "should return nil" do
					hv = {}
					result = ZCRMModule.new(@zclient, hv, @default_meta_folder)
					expect(result).to be_nil
				end
			end
			context "it does not contain module meta_data" do
				it "should return nil" do
					hv = {key1: 1, key2: 2, key3: 3}
					result = ZCRMModule.new(@zclient, hv, @default_meta_folder)
					expect(result).to be_nil
				end
			end
		end
		context "invalid meta_folder" do
			it "should return nil " do
				hv = @leads_hv
				result = ZCRMModule.new(@zclient, hv, @invalid_folder)
			end
		end
	end
=end
end #describe ZCRMModule