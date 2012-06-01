#ifndef SAFE_EXEC_HPP
#define SAFE_EXEC_HPP
#include <node.h>
#include <node_buffer.h>
#include <stdexcept>
using namespace v8;
using namespace node;

template<typename FunctionType> static Handle<Value> SafeExecFunction(const Arguments &args,FunctionType &callback)
{
	v8::TryCatch try_catch;
	Handle<Value> res=callback(args);

	if(try_catch.HasCaught())
	{
		return v8::ThrowException(try_catch.Exception());
	}
	return res;
}
#endif
