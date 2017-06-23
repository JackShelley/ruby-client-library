require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMRecord


	def initialize(module_name, hash_values, fields)
		@module_name = module_name
		@hash_values = hash_values
		@fields = fields
		@modified_fields = {}
		@added_fields = {}
		@unavailable_fields = []
		@fields_sent_lastupdate = []
		@error_fields_lastupdate = []
		@is_deleted = false
		@is_record_marked_for_deletion = false
		if !hash_values.nil? then
			@record_id = hash_values['id']
		else
			@record_id = nil
		end
	end

	def get(key)
		return @hash_values[key]
	end

	def set(key, value)
		field = @fields[key]
		data_type = ""
		if field.nil? then
			length = @unavailable_fields.length
			@unavailable_fields[length] = key
		elsif
			data_type = field.get_datatype
		end
		current_value = get(key)
		if current_value.nil? then
			added_fields[key] = current_value
			hash_values[key] = value
			return true
		else
			return update(key,value,current_value, data_type)
		end
	end

	def update(key, value, current_value="", data_type="")
		#The function returns two values, 
		#1) boolean - to say if the new value is over-written successfully
		#2) message - Result of the function in words
		message = "Value updated locally"

		if current_value.empty? then
			current_value = get(key)
		end
		if current_value.nil? then
			message = "Field cannot be found, try 'set' method to add a new key."
			return false, message
		elsif current_value.class != value.class then
			message = "Datatype mismatch, with current_value of the field. Please check the given value." 
			if !data_type.empty? 
				message = message+" Further info: field is of datatype "+data_type
			end
			return false, message
		else
			@modified_fields[key] = current_value
			@hash_values[key] = value
			return true, message
		end
	end

	#Getters and setters :: Named in a fashion easier to understand for api users
	def delete
		is_record_marked_for_deletion = true
	end
	def undo_delete
		is_record_marked_for_deletion = false
	end

	def construct_upsert_hash

		required_fields = get_required_fields

		required_fields_available = true
		required_fields.each do |field_name|
			val = get(field_name)
			if val.nil? then
				required_fields_available = false
			end
		end

		if !required_fields_available then
			return false, nil
		end

		update_hash = {}

		#update_hash['data'] = update_hash
		if !self.record_id.nil? then
			update_hash['id'] = self.record_id
			print "After adding id jsonkey ::: ", "\n"
		end

		print "Added fields ====> ", "\n"
		print @added_fields, "\n"
		print @modified_fields, "\n"

		@added_fields.each do |field_name, current_value| 
			update_hash[field_name] = get(field_name)
		end
		@modified_fields.each do |field_name, current_value|
			update_hash[field_name] = get(field_name)
		end

		print "Printing final update hash ====> ", "\n"
		print true, update_hash
		print "\n"
		return true, update_hash
	end

	#Utility function below
	def construct_update_hash #Contains a lot of print statements: Please remove when the function is working properly
		print 'Inside construct_update_hash :::: ', "\n"
		#Check for id presence when you are writing this function
		#If there's no id then you just have to no include it in the final update_hash
		update_hash = {}

		#update_hash['data'] = update_hash
		if !self.record_id.nil? then
			update_hash['id'] = self.record_id
			print "After adding id jsonkey ::: ", "\n"
		end

		print "Added fields ====> ", "\n"
		print @added_fields, "\n"
		print @modified_fields, "\n"

		@added_fields.each do |field_name, current_value| 
			update_hash[field_name] = get(field_name)
		end
		@modified_fields.each do |field_name, current_value|
			update_hash[field_name] = get(field_name)
		end

		print "Printing final update hash ====> ", "\n"
		print update_hash
		print "\n"
		return update_hash
	end

	def record_errors(record_obj)
		temp_list = record_obj.keys
		@error_fields_lastupdate = @fields_sent_lastupdate - temp_list
		@update_cycle_complete = true
	end
	def get_errorfields_lastupdate
		if @update_cycle_complete then
			return @error_fields_lastupdate
		end
	end
	def check_fields
		res = false
		if @hash_values.empty? then
			return false
		else
			fieldlist = self.get_field_list
			returned_fieldlist = @hash_values.keys
			l1 = fieldlist.length
			l2 = returned_fieldlist.length
			if l2 > l1
				res = true 
			else
				res = false
			end
		end
		return res
	end

	def get_field_list
		res = []
		@fields.each do |field_id, field_obj|
			res[res.length] = field_obj.field_name
		end
		return res
	end
	def module_name
		return @module_name
	end
	def record_id
		return @record_id
	end
	private :update
end