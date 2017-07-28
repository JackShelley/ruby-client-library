module Constants
	DEF_ACCOUNTS_URL = "https://accounts.zoho.com/"
	ACCOUNTS_URL = "https://accounts.zoho."
	DEF_CRMAPI_URL = "https://www.zohoapis.com/crm/v2/"
	ZOHOAPIS_URL = "https://www.zohoapis."
	V2_PATH = "/crm/v2/"
	DEF_CRMDATA_API_URL = "https://www.zohoapis.com/crm/api/v2/" #This looks like it may not be needed #ISSUE01 with the help document
	INVALID_URI_EXCEPTION = "The request url is invalid, please check and proceed"
	EMPTY_HEADER_EXCEPTION = "Headers is empty, Authorization will fail"
	TOBEGENERATED = :to_be_generated
	URL_PATH_SEPERATOR = "/"
	NO_RECORD_TO_UPDATE = "No Record to update"
	MAND_FIELDS_NOT_SET = "Mandatory fields for some records have not been set. Please check and retry."
	GENERAL_SUCCESS_MESSAGE = "success"
	UPSERT_FAIL_MESSAGE = "Some records failed to upsert"
	EMPTY_RECORDS_MSG = "Records are empty"
	INVALID_TOKEN_MSG = "INVALID_TOKEN"
	USE_UPDATE_FUNC = "The module does not support create action but it supports edit. Please use update function instead of upsert."
	MODULE_DOESNT_SUPPORT_CREATE = "The module does not support create or edit action. Please check and proceed."
	
end