require "ZohoCRM_Client"

RSpec.describe ZCRMModule do
	before do
		@zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a67dfebe56ae6bb8", "1000.7461b182dfddc8e94bf1ec3d9d770fdb.73dc7bb4ae2445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@default_meta_folder = "/Users/kamalkumar/ref_data1"
		@apiObj = Api_Methods.new(zclient, @default_meta_folder)
		@improper_zclient = ZohoCRMClient.new("1000.UZ62A7H7Z1PX25610YHMBNIFP7BJ17", "defd547a919eecebeed00ce0c2a5a4a2f24c431cc6", "1000.07575fda88b3dbd73ff279a9af75aa06.c2b0c2add3a09be9a6asdvsdebe56ae6bb8", "1000.7461b182dfddc8e94bf1ec3d9d770fdb.73dc7bb4aedsvsdvsd445a089d0a6c196fa7101", "http://ec2-52-89-68-27.us-west-2.compute.amazonaws.com:8080/V2APITesting/Action")
		@lObj = @apiObj.load_crm_module("Leads")
		@leads_hv = @lObj.get_hash_values
		@invalid_folder = "/this/folder/does/not/exist"
		@module_list = Meta_data.get_module_list(@zclient, true)
		@leads_fields = @lObj.get_fields

	end

	describe ".update_record" do
		context "record is nil", :focus => true do
			it "should return nil" do
				record = nil
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.update_record(id)
					#Expectations
					expect(record).to be_nil
				end
			end
		end
		context "record is not of type ZCRMRecord", :focus => true do
			it "should return nil" do
				record = "nil"
				list = @module_list.keys
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.update_record(id)
					#Expectations
					expect(record).to be_nil
				end
			end
		end
	end #describe .update_record

	describe ".get_record" do
		context "id is nil" do
			it "should return nil" do
				id = nil
				list = @module_list
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
				list = @module_list
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
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					record = mod_obj.get_record(id)
					#Expectations
					expect(record).to be_nil
				end
			end
		end
		context "id is correct but belongs to a different module" do
			#204 no content
			it "should return nil" do
				expect(false).to be_eq(true)
			end
		end
		context "id is proper " do
			it "should return a valid ZCRMRecord" do
				expect(false).to be_eq(true)
			end
		end
	end

	describe ".delete_records" do
		context "ids is nil" do
			it "should return false, and an empty array" do
				ids = nil
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to be_eq(false)
					expect(o2).to be_empty
				end
			end
		end
		context "ids is empty" do
			it "should return false, and an empty array " do
				ids = []
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to be_eq(false)
					expect(o2).to be_empty
				end
			end
		end
		context "ids are wrong" do
			it "should return false, and array containing ids that failed" do
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					n_recs = 1 + rand(50)
					records = mod_obj.get_records(n_recs)
					records.each do |r_id, r_obj|
						ids[ids.length] = r_id + 100000000000
					end
					o1, o2 = mod_obj.delete_records(ids)
					expect(o1).to be_eq(false)
					expect(o2).not_to be_empty
					o2.should =~ ids
				end
			end
		end
		context "ids are partially wrong" do
			it "should return false, and array containing ids that failed " do
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					val_ids = []
					inv_ids = []
					n_vals = 1 + rand(50)
					records = mod_obj.get_records(n_vals)
					records.each do |r_id, r_obj|
						val_ids[val_ids.length] = r_id
						inv_ids[inv_ids.length] = r_id + 100000000000
					end
					ids = val_ids + inv_ids
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to be_eq true
					expect(o2).not_to be_nil
					expect(o2).not_to be_empty
					o2.should =~ inv_ids
				end
			end
		end
		context "multiple ids, all are valid ids" do
			it "should return true, and an empty signifying that there are no failures" do
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					ids = []
					n_vals = 1 + rand(50)
					records = mod_obj.get_records()
					records.each do |r_id, r_obj|
						ids[ids.length] = r_id
					end
					o1, o2 = mod_obj.delete_records(ids)
					#Expectations
					expect(o1).to be_eq true
					expect(o2).to be_instance_of(Array)
					expect(o2).to be_empty
				end
			end
		end
	end

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
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					all_fields = mod_obj.get_fields
					n_fields_to_be_upd = 1 + rand(all_fields.length)
					records = []
					n_recs_upd = 1 + rand(50)
					n_recs_ins = 1 + rand(50)
					upd_records = mod_obj.get_records(n_recs_upd)
					n_recs_upd = upd_records.size
					req_fields = mod_obj.get_fields
					req_field_objs = []
					req_fields.each do |temp|
						req_field_objs = all_fields[temp]
					end
					upd_records.each do |r_id, r_obj|
						req_field_objs.each do |f_obj|
							f_name = f_obj.field_name
							value = ZCRMField.get_test_data(f_name)
							r_obj.set(f_name, value)
						end
					end
					ins_records = []
					n_recs_ins.times do |i|
						r_obj = mod_obj.get_new_record
						req_fields_objs.each do |f_obj|
							f_name = f_obj.field_name
							value = ZCRMField.get_test_data(f_name)
							r_obj.set(f_name, value)
						end
						ins_records[ins_records.length] = r_obj
					end
					records = upd_records + ins_records
					n_sent_recs = records.length
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to be_eq(true)
					expect(o2).to be_eq(Constants::GENERAL_SUCCESS_MESSAGE)
					expect(o3.length).to be_eq(n_sent_recs)
				end
			end
		end
		context "records are empty" do
			it "should return false, record_empty message and an empty array" do
				records = []
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to be_eq(false)
					expect(o2).to be_eq(Constants::EMPTY_RECORDS_MSG)
					expect(o3).to be_empty
				end
			end
		end
		context "the records do not have all the required fields set" do
			it "returns false and error message " do
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					all_fields = mod_obj.get_fields
					req_fields = mod_obj.get_required_fields
					#n_recs_per_page = 1 + rand(50)
					n_new_recs = 1 + rand(50)
					n_inv_recs = n_new_recs/2
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
							value = ZCRMField.get_test_data(rf_obj, @apiObj)
							inv_r.set(field_name, value)
						end
						inv_records[inv_records.length] = inv_r
					end
					n_val_recs = n_inv_recs
					val_records = []
					n_val_recs.times do |i|
						val_r = mod_obj.get_new_record
						req_fields.each do |rf_id|
							rf_obj = all_fields_ids[rf_id]
							field_name = rf_obj.field_name
							value = ZCRMField.get_test_data(rf_obj, @apiObj)
							val_r.set(field_name, value)
						end
						val_records[val_records.length] = inv_r
					end
					records = val_records + inv_records
					o1, o2, o3 = mod_obj.upsert(records)
					#Assertions
					expect(o1).to be_eq(false)
					expect(o2).to be_eq(Constants::MAND_FIELDS_NOT_SET)
					expect(o3.length).to be_eq(n_inv_recs) 
					#SUGGEST: #We can have a attribute for zcrmrecord called req_fields_not_set=[].
				end
			end
		end
	end

	describe ".update_records" do
		context "records is empty" do
			it "returns false and error message" do
				records = {}
				r1,r2 = @lObj.update_records(records)
				expect(r1).to be_eq(false)
				expect(r2).to be_instance_of(String)
				expect(r2).to be_eq(Constants::NO_RECORD_TO_UPDATE)
			end
		end
		context "records passed have not been updated" do
			it "returns success_ids and failed_ids, the records passed have not been updated!" do
				records = {}
				list = @module_list
				n_recs = 1 + rand(200)
				list.each do |mod|
					mod_obj = @zclient.load_crm_module(mod)
					records = mod_obj.get_records(n_recs)
					record_ids = records.keys
					size = records.size
					h_size = size/2
					temp = h_size.times.map{1 + rand(size)}
					not_updated_ids = []
					temp.each do |seq|
						temp_id = record_ids[seq]
						not_updated_ids[not_updated_ids.length] = temp_id
					end
					to_be_updated_fields = {}
					all_fields = mod_obj.get_fields
					all_fields_ids = all_fields.keys
					number_of_fields_to_update = 1 + rand(all_fields.length)
					to_update_f_seqs = number_of_fields_to_update.times.map{ 1 + rand(all_field.length)}
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
							data_type = field_obj.data_type
							value = ZCRMField.get_test_data(data_type)
							r.update(f_name, value)
						end
					end
				end
				s_ids = record_ids - not_updated_ids
				f_ids = not_updated_ids
				r_s_ids,r_f_ids = @lObj.update_records(records)
				#Assertions
				expect(r1).not_to be_nil
				expect(r2).not_to be_nil
				r_s_ids =~ s_ids
				r_f_ids =~ f_ids
			end
		end
		context "all fields are being updated, for all the modules" do
			it "should return all the ids in success_ids and none in failure_ids" do
				list = @module_list
				list.each do |mod|
					mod_obj = @apiObj.load_crm_module(mod)
					rand_per_page = 1 + rand(200)
					records = mod_obj.get_records(rand_per_page)
					record_ids = records.keys
					all_fields = mod_obj.get_fields
					records.each do |record|
						all_fields.each do |f_id, f_obj|
							f_name = f_obj.field_name
							data_type = f_obj.data_type
							value = ZCRMField.get_test_data(f_obj, @apiObj)
							record.set(data_type, value)
						end
					end
					s_ids, f_ids = mod_obj.update_records(records)
					#Assertions
					s_ids.should =~ record_ids
					expect(f_ids).to be_empty
				end
			end
		end
	end

	describe ".get_records" do
		#def get_records(per_page=200, fields=[], page=1, sort_order='', approved=false, converted=false)
		context "Wrong inputs" do
			context "per_page has invalid values" do
				it "should take the default value for per_page and get records according to other params" do
					per_page = ""
					ids = @leads_fields.keys
					n_fields = ids.length
					rand_num = 1 + rand(n_fields)
					a_field_id = ids[rand_num]
					a_field = @leads.fields[field_id]
					a_field_name = a_field.field_name
					b_field_id = ids[rand_num+1]
					b_field_name = @leads.fields[b_field_id].field_name
					fields[0] = a_field_name
					page = 1
					sort_order = "desc"
					records = @lObj.get_records(per_page, fields, page, sort_order)
					records.each do |record|
						id = record.record_id
						val = record.get(field_name)
						expect(val).not_to be_nil
						val = record.get(b_field_name)
						expect(val).to be_nil
					end
				end
			end
			context "fields is invalid values" do
				it "should take default values for fields and get records according to other params" do
					per_page = 50
					fields = "Invalid_fields_value"
					page=1
					records = @lObj.get_records(per_page, fields, page, sort_order)
					#Assertions
					expect(records).not_to be_nil
					expect(records.size).to be_eq(per_page)
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
						break if count >= inv_fields_count
					end
					v_f_seq = 10.times.map{1+rand(field_ids_arr.length)}
					v_f_seq = v_f_seq.uniq
					v_fields = []

					v_f_seq.each do |f_seq|
						f_id = field_ids_arr[f_seq]
						f_name = @leads_fields[f_id].field_name
						v_fields[v_fields.length] = f_name
					end
					fields_param = v_fields + invalid_fields
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
					rand_num = 1 + rand(field_ids_arr.length)
					a_field_id = field_ids_arr[rand_num]
					b_field_id = field_ids_arr[rand_num+1]
					a_field_obj = @leads_fields.get_fields[a_field_id] 
					b_field_obj = @leads_fields.get_fields[b_field_id]
					a_field_name = @a_field_obj.field_name
					b_field_name = @b_field_ob.field_name
					fields[0] = a_field_name
					page = "Invalid entry "
					records = @lObj.get_records(per_page, fields, page, sort_order)
					#Assertions
					expect(records).not_to be_nil
					expect(records).to be_instance_of(Hash)
					expect(records.size).to be_eq(100)
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
					expect(records.size).to be_eq(100)
				end
			end
		end
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
					list = @module_list

					list.each do |module_name|
						mod_obj = @apiObj.load_crm_module(module_name)
						#ASC sort order 										#approved=false #converted=false
						page = 1
						asc_sort_ids = []
						asc_temp_ids = []
						n_recs_per_page = 1 + rand(200) #Generates random number from 0-199.
						loop do
							records = mod_obj.get_records(n_recs_per_page, [], page, "asc")
							size = records.size
							records.each do |id, records|
								asc_temp_ids[asc_temp_ids.length] = id
							end
							temp = asc_temp_ids - asc_sort_ids
							expect(temp.length).to be_eq(0)
							asc_sort_ids.concat(asc_temp_ids)
							break if (size<n_recs_per_page || page > 2)
							page++
						end

						#DESC sort order
						page = 1
						desc_sort_ids = []
						desc_temp_ids = []
						loop do
							records = mod_obj.get_records(n_recs_per_page, [], page, "desc")
							size = records.size
							records.each do |id, records|
								desc_temp_ids[desc_temp_ids.length] = id
							end
							temp = asc_temp_ids - asc_sort_ids
							expect(temp.length).to be_eq(0)
							desc_sort_ids.concat(desc_temp_ids)
							break if (size<n_recs_per_page || page > 2)
						end
						asc_sort_ids.should =~ desc_sort_ids
						temp_desc_ids = desc_sort_ids.reverse
						asc_sort_ids.should == temp_desc_ids

					end
				end

			end
			context "For all modules, passing a list of fields along the params" do
				it "should have only the fields passed along the params" do
					list = @module_list
					list.each do |module_name|
						url = Constants::DEF_CRMAPI_URL + module_name
						mod_obj = @apiObj.load_crm_module(module_name)
						fields = mod_obj.get_fields
						n_avail_fields = fields.length
						n_fields_to_send = 1 + rand(n_avail_fields)
						field_seq_arr = n_fields_to_send.times.map{1 + rand(n_fields_to_send)}
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
						log("We are making a get_records call, with the following fields ")
						log(field_csv)
						n_recs_per_page = 1 + rand(200) 
						records = mod_obj.get_records(n_recs_per_page, fields_param)
						records.each do |id, record|
							record_hash = record.get_hash_values
							fields_returned = record_hash.keys
							if fields_returned.include? "id" then
								field_returned.delete("id")
							end
							if fields_returned.include? "$editable" then
								fields_returned.delete("$editable")
							end
						end
						expect(fields_returned.size).to be_eq(field_seq_arr.size)
						fields_returned.should =~ field_seq_arr
					end
				end
			end
		end
	end

	describe ".construct_GET_params" do
		context "testing is not needed for this " do
			it "should be true" do
				expect(false).to be_eq true
			end
		end
	end

	describe ".populate_required_fields" do
		context "Every module has required fields" do
			it "the marked required fields should be same as the one's from the Api's" do
				list = @module_list
				list.each do |module_name|
					url = Constants::DEF_CRMAPI_URL + Constants::URL_PATH_SEPERATOR + "settings/modules" + module_name
					headers = @zclient.construct_headers
					params = {}
					response = @zclient._get(url, params, headers)
					body = response.body
					json_list = Api_Methods._get_list(body, "modules")
					json = json_list[0]
					api_name = json['api_name']
					singular_label = json['singular_label']
					plural_label = json['plural_label']
					mod_obj = ZCRMModule.new(zclient, json, meta_folder, api_name, singular_label, plural_label)
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
					req_field_ids = mod_obj.populate_required_fields
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
					expect(m_req_fields.length).to be_eq(req_field_ids.length)
					expect(m_req_fields).to be_eq(req_field_ids)
					assert1 = (m_req_fields - req_field_ids).blank? and (req_field_ids - m_req_fields).blank?
					expect(assert1).to be_eq(true)
					fields = mod_obj.get_fields
					fields.each do |id, field|
						if req_field_ids.include? id then
							expect(field.is_required).to be_eq true
						end
					end
				end
			end

		end
	end

	describe ".get_required_fields" do
		context "creating a new_record by only setting values for the required fields" do
			it "record should be created" do
				#Doing the same for all the modules
				list = @module_list
				list.each do |module_name|
					mod_obj = @apiObj.load_crm_module(module_name)
					record = mod_obj.get_new_record
					req_fields = mod_obj.get_required_fields
					fields = mod_obj.get_fields
					fields.each do |id, field|
						if req_fields.include? id || field.is_required then
							data_type = field.data_type
							value = ZCRMField.get_test_data(data_type, @apiObj)
							field_name = field.field_name
							field.set(field_name, value)
						end
					end
					records = []
					records[0] = record
					result = upsert(record)
					expect(result).not_to be_nil
					result.each do |id, r_obj|
						expect(id).not_to be_nil
						expect(r_obj).not_to be_nil
						expect(r_obj.module_name).to be_eq(module_name)
						expect(id).to be_eq(r_obj.record_id)
						expect(r_obj.class).to be_eq(ZCRMRecord) 
					end
				end
			end
		end
	end

	describe ".get_new_record" do
		context "for every module we should end up with a ZCRMRecord object" do
			it "should return a new record for module_obj's module" do
				list = @module_list
				list.each do |module_name|
					mod_obj = @apiObj.load_crm_module(module_name)
					record = mod_obj.get_new_record
					expect(record).not_to be_nil
					expect(record.class).to be_eq('ZCRMRecord')
					expect(record.module_name).to be_eq(module_name)
				end
			end
		end
	end

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
end
