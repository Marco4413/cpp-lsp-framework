#include <cassert>
#include <lsp/messagehandler.h>

namespace lsp{
namespace{

thread_local MessageId* t_currentRequestId  = nullptr;

json::Integer nextUniqueRequestId()
{
	static std::atomic<json::Integer> s_uniqueRequestId = 0;
	return ++s_uniqueRequestId;
}

}

MessageHandler::MessageHandler(Connection& connection, unsigned int maxResponseThreads)
	: m_connection{connection}
	, m_threadPool(0, maxResponseThreads)
{
}

void MessageHandler::processIncomingMessages()
{
	auto messageJson = m_connection.readMessage();

	if(messageJson.isObject())
	{
		auto message = jsonrpc::messageFromJson(std::move(messageJson.object()));

		if(auto* request = std::get_if<jsonrpc::Request>(&message); request)
		{
			auto response = processRequest(std::move(*request), true);

			if(response.has_value())
				m_connection.writeMessage(jsonrpc::responseToJson(std::move(*response)));
		}
		else
		{
			auto& response = std::get<jsonrpc::Response>(message);
			processResponse(std::move(response));
		}
	}
	else if(messageJson.isArray())
	{
		auto messageBatch = jsonrpc::messageBatchFromJson(std::move(messageJson.array()));

		if(auto* requests = std::get_if<jsonrpc::RequestBatch>(&messageBatch))
		{
			jsonrpc::ResponseBatch responses;
			responses.reserve(requests->size());

			for(auto&& r : *requests)
			{
				auto response = processRequest(std::move(r), false);

				if(response.has_value())
					responses.push_back(std::move(*response));
			}

			if(!responses.empty())
				m_connection.writeMessage(jsonrpc::responseBatchToJson(std::move(responses)));
		}
		else
		{
			auto& responses = std::get<jsonrpc::ResponseBatch>(messageBatch);
			// This should never be called as no batches are ever sent
			for(auto&& r : responses)
				processResponse(std::move(r));
		}
	}
	else
	{
		throw jsonrpc::ProtocolError{"Expected message to be a json object or array"};
	}
}

const MessageId& MessageHandler::currentRequestId()
{
	assert(t_currentRequestId);
	if(!t_currentRequestId)
		throw std::logic_error("MessageHandler::currentRequestId called outside of a request context");

	return *t_currentRequestId;
}

void MessageHandler::remove(std::string_view method)
{
	std::lock_guard lock{m_requestHandlersMutex};

	if(const auto it = m_requestHandlersByMethod.find(method); it != m_requestHandlersByMethod.end())
		m_requestHandlersByMethod.erase(it);
}

MessageHandler::OptionalResponse MessageHandler::processRequest(jsonrpc::Request&& request, bool allowAsync)
{
	std::unique_lock lock{m_requestHandlersMutex};
	OptionalResponse response;

	if(const auto handlerIt = m_requestHandlersByMethod.find(request.method);
	   handlerIt != m_requestHandlersByMethod.end() && handlerIt->second)
	{
		assert(!t_currentRequestId);
		if(request.id.has_value())
			t_currentRequestId = &request.id.value();

		try
		{
			lock.unlock();

			// Call handler for the method type and return optional response
			response = handlerIt->second(
				request.params.has_value() ? std::move(*request.params) : json::Null{},
				allowAsync);
		}
		catch(const RequestError& e)
		{
			if(!request.isNotification())
			{
				response = jsonrpc::createErrorResponse(
					*request.id, e.code(), e.what(), e.data());
			}
		}
		catch(const json::TypeError& e)
		{
			if(!request.isNotification())
			{
				response = jsonrpc::createErrorResponse(
					*request.id, Error::InvalidParams, e.what());
			}
		}
		catch(const std::exception& e)
		{
			if(!request.isNotification())
			{
				response = jsonrpc::createErrorResponse(
					*request.id, Error::InternalError, e.what());
			}
		}
		catch(...)
		{
			t_currentRequestId = nullptr;
			throw;
		}

		t_currentRequestId = nullptr;
	}
	else
	{
		if(!request.isNotification())
			response = jsonrpc::createErrorResponse(*request.id, Error::MethodNotFound, "Method not found");
	}

	return response;
}

void MessageHandler::processResponse(jsonrpc::Response&& response)
{
	RequestResultPtr result;

	// Find pending request for the response that was received based on the message id.
	{
		std::lock_guard lock{m_pendingRequestsMutex};
		if(auto it = m_pendingRequests.find(response.id); it != m_pendingRequests.end())
		{
			result = std::move(it->second);
			m_pendingRequests.erase(it);
		}
	}

	if(!result) // If there's no result it means a response was received without a request which makes no sense but just ignore it...
		return;

	try
	{
		assert(!t_currentRequestId);
		t_currentRequestId = &response.id;

		if(response.result.has_value())
		{
			result->setValueFromJson(std::move(*response.result));
		}
		else // Error response received. Create an exception.
		{
			assert(response.error.has_value());
			const auto& error = *response.error;
			result->setException(std::make_exception_ptr(ResponseError{error.code, error.message, error.data}));
		}
	}
	catch(...)
	{
		t_currentRequestId = nullptr;
		throw;
	}

	t_currentRequestId = nullptr;
}

void MessageHandler::addHandler(std::string_view method, HandlerWrapper&& handlerFunc)
{
	std::lock_guard lock{m_requestHandlersMutex};
	m_requestHandlersByMethod[std::string(method)] = std::move(handlerFunc);
}

void MessageHandler::sendResponse(jsonrpc::Response&& response)
{
	m_connection.writeMessage(jsonrpc::responseToJson(std::move(response)));
}

MessageId MessageHandler::sendRequest(std::string_view method, RequestResultPtr result, const std::optional<json::Any>& params)
{
	std::lock_guard lock{m_pendingRequestsMutex};
	const auto messageId = nextUniqueRequestId();
	m_pendingRequests[messageId] = std::move(result);
	auto request = jsonrpc::createRequest(messageId, method, params);
	m_connection.writeMessage(jsonrpc::requestToJson(std::move(request)));
	return messageId;
}

void MessageHandler::sendNotification(std::string_view method, const std::optional<json::Any>& params)
{
	auto notification = jsonrpc::createNotification(method, params);
	m_connection.writeMessage(jsonrpc::requestToJson(std::move(notification)));
}

} // namespace lsp
