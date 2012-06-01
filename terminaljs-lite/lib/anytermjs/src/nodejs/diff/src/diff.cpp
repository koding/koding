#include <cstdlib>
#include <node.h>
#include <node_buffer.h>

#include <string>

#include "diff.hh"

using namespace v8;
using namespace node;

static Handle<Value> Parse(const Arguments& args)
{
	HandleScope scope;
	std::string str1=*(String::Utf8Value(args[0]->ToString()));
	std::string str2=*(String::Utf8Value(args[1]->ToString()));

	Local<Function> callback = Local<Function>::Cast(args[2]);

	DiffAlgo::string_fragment_seq seq;
	
	DiffAlgo::string_diff(str1,str2,seq);

	

	for(DiffAlgo::string_fragment_seq::iterator it=seq.begin();it!=seq.end();++it)
	{
		v8::Handle<Value> argv[2]={Integer::New(it->first),
			String::New(it->second.c_str(),it->second.size())
		};
		callback->Call(callback, 2, argv);
	}

	return Undefined();
}

extern "C" void
init(Handle<Object> target)
{
	HandleScope scope;
	NODE_SET_METHOD(target, "parseDiff", Parse);
}
