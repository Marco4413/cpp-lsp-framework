#pragma once

#include <string>
#include <vector>
#include <cstdint>
#include <variant>
#include <string_view>
#include <lsp/strmap.h>
#include <lsp/exception.h>

namespace lsp::json{

/*
 * Types
 */

class Any;

using Null    = std::nullptr_t;
using Boolean = bool;
using Decimal = double;
using Integer = std::int32_t;
using String  = std::string;
using Array   = std::vector<Any>;

/*
 * Errors
 */

class TypeError : public Exception{
public:
	TypeError(const std::string& message = "Unexpected json value") : Exception{message}{}
};

class ParseError : public Exception{
public:
	ParseError(const std::string& message, std::size_t textPos)
		: Exception{message}
	  , m_textPos{textPos}{}

	std::size_t textPos() const noexcept{ return m_textPos; }

private:
	 std::size_t m_textPos = 0;
};

/*
 * Object
 */

using ObjectMap = StrMap<String, Any>;
class Object : public ObjectMap{
public:
	using ObjectMap::ObjectMap;

	Any& get(std::string_view key);
	const Any& get(std::string_view key) const;
};

/*
 * Any
 */

using AnyVariant = std::variant<Null, Boolean, Integer, Decimal, String, Object, Array>;
class Any : private AnyVariant{
	using AnyVariant::AnyVariant;
public:
	Any() : AnyVariant{nullptr}{}

	bool isNull() const{ return std::holds_alternative<Null>(*this); }
	bool isBoolean() const{ return std::holds_alternative<Boolean>(*this); }
	bool isInteger() const{ return std::holds_alternative<Integer>(*this); }
	bool isDecimal() const{ return std::holds_alternative<Decimal>(*this); }
	bool isNumber() const{ return isInteger() || isDecimal(); }
	bool isString() const{ return std::holds_alternative<String>(*this); }
	bool isObject() const{ return std::holds_alternative<Object>(*this); }
	bool isArray() const{ return std::holds_alternative<Array>(*this); }

	Boolean boolean() const{ return get<Boolean>(); }
	Integer integer() const{ return get<Integer>(); }
	Decimal decimal() const{ return get<Decimal>(); }
	const String& string() const{ return get<String>(); }
	String& string(){ return get<String>(); }
	const Object& object() const{ return get<Object>(); }
	Object& object(){ return get<Object>(); }
	const Array& array() const{ return get<Array>(); }
	Array& array(){ return get<Array>(); }

	Decimal number() const
	{
		if(isDecimal())
			return get<Decimal>();

		if(isInteger())
			return static_cast<Decimal>(get<Integer>());

		throw TypeError{};
	}

private:
	template<typename T>
	T& get()
	{
		if(std::holds_alternative<T>(*this))
			return std::get<T>(*this);

		throw TypeError{};
	}

	Any& get()
	{
		return *this;
	}

	template<typename T>
	const T& get() const
	{
		if(std::holds_alternative<T>(*this))
			return std::get<T>(*this);

		throw TypeError{};
	}

	const Any& get() const
	{
		return *this;
	}
};

/*
 * parse/stringify
 */

Any         parse(std::string_view text);
std::string stringify(const Any& json, bool format = false);
std::string toStringLiteral(std::string_view str);
std::string fromStringLiteral(std::string_view str);

} // namespace lsp::json
