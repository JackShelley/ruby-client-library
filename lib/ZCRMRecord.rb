require 'ZohoCRM_Client'
require 'json'
require 'yaml'
require 'rest-client'
require 'time'

class ZCRMRecord

	#@module_name
	#@hash_values
	#@modified_fields = {}
	#@added_fields = {}
	#@unavailable_fields = []
	#@fields = {}
	#@fields_sent_lastupdate = []
	#@error_fields_lastupdate = []
	#@update_cycle_complete
	#@is_record_marked_for_deletion = false
	#@is_deleted = false


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
		end
	end

	def get(key)
		return @hash_values[key]
	end

	def set(key, value)
		field = @fields.get(key)
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
		elsif
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
			if !data_type.empty? then
				message = message+" Further info: field is of datatype "+data_type
			end
			return false, message
		else
			modified_fields[key] = current_value
			hash_values[key] = value
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

	#Utility function below
	def construct_update_hash
		update_hash = {}

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
		if hash_values.empty? then
			return false
		else
			fieldlist = self.get_field_list(fields)
			returned_fieldlist = hash_values.keys
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

	def get_field_list(fields)
		res = []
		fields.each do |field_id, field_obj|
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
end