# lsp-framework

This is an implementation of the [Language Server Protocol](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/) in C++. It can be used to implement both servers and clients that communicate using the LSP.
Please note that this project is a work in progress. While it provides a functioning implementation of the LSP, there may be some missing features or issues.

## Dependencies

There aren't any external dependencies except for `cmake` and a compiler that supports C++20.

## Usage

The project is built as a static library. LSP type definitions, messages and serialization boilerplate are generated during the build from the official [meta model](https://github.com/microsoft/language-server-protocol/blob/gh-pages/_specifications/lsp/3.17/metaModel/metaModel.json).  
  
Here's a short example on how to handle and send requests:
```cpp
#include <lsp/messages.h> // Generated message definitions
#include <lsp/connection.h>
#include <lsp/messagehandler.h>

...

lsp::Connection connection{std::cin, std::cout};
lsp::MessageHandler messageHandler{connection};

bool running = true;

messageHandler.handler<lsp::messages::Initialize>([](const auto& params){ // Initialize request
  lsp::messages::Initialize::Result result;
  // Fill out the initialize result and return it or throw a lsp::RequestError if there was a problem
  return result;
}).handler<lsp::messages::Exit>([&running](){ // Exit notification
  running = false;
});

while(running)
  messageHandler.processIncomingMessages();

// The sendRequest method returns a std::future.
// Be careful not to call std::future::wait on the same thread that calls
// MessageHandler::processIncomingMessages since it would block.

std::future<lsp::messages::TextDocument_Diagnostic::Result> result =
  messageHandler.sendRequest<lsp::messages::TextDocument_Diagnostic>
  (
    "<unique_request_id>",
    lsp::messages::TextDocument_Diagnostic::Params{}
  );

```
## License

This project is licensed under the [MIT License](LICENSE).
