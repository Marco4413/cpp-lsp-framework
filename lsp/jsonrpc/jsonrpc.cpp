#include "jsonrpc.h"

namespace lsp::jsonrpc{
namespace{

json::Value idToJson(const Id& id){
	if(std::holds_alternative<json::String>(id))
		return std::get<json::String>(id);

	if(std::holds_alternative<json::Number>(id))
		return std::get<json::Number>(id);

	return {};
}

json::Object errorToJson(const Error& error){
	json::Object json;

	json["code"] = json::Number(error.code);
	json["message"] = error.message;

	if(error.data.has_value())
		json["data"] = error.data.value();

	return json;
}

}

Request requestFromJson(const json::Value& json){
	Request request;

	if(!std::holds_alternative<json::Object>(json))
		return {}; // ERROR: Expected json object

	const auto& object = std::get<json::Object>(json);
	auto it = object.find("jsonrpc");

	if(it == object.end() || !std::holds_alternative<json::String>(it->second) || std::get<json::String>(it->second) != "2.0")
		return {}; // ERROR: Unsupported or missing jsonrpc version

	it = object.find("method");

	if(it == object.end() || !std::holds_alternative<json::String>(it->second))
		return {}; // ERROR: Missing or invalid method

	return request;
}

json::Value responseToJson(const Response& response){
	json::Object json;

	json["jsonrpc"] = response.jsonrpc;
	json["id"] = idToJson(response.id);

	if(response.result.has_value())
		json["result"] = response.result.value();

	if(response.error.has_value())
		json["error"] = errorToJson(response.error.value());

	return json;
}

}