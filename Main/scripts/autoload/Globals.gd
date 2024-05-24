extends Node

@export var api_url: String = "https://grad-api.smorsoft.com";
@export var turn_urls: Array[String] = ["turn:turn1.smorsoft.com:3478", "stun:turn1.smorsoft.com"];

func CreateHTTPRequest(base_url: String, path: String, parameters: Array):
	var request = base_url + path;
	if (parameters.size() > 0):
		request += "?";
		for parameter in parameters:
			request += parameter.name + "=";
			request += parameter.value + "&";
	request = request.left(request.length() - 1)
	
	return request;

var element_unique_id: int = 0;
func GetElementUniqueId() -> String:
	self.element_unique_id += 1;
	return str(self.element_unique_id);
