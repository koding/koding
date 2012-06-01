#include <cstdlib>
#include <node.h>
#include <node_buffer.h>

#include <string>

#include "screen_wrap.hpp"
#include "Iconver.hh"
#include "html.hh"

using namespace v8;
using namespace node;

pbe::Iconver<pbe::valid,ucs4_char,utf8_char> ucs4_to_utf8(UCS4_NATIVE,"UTF-8");

static Handle<Value> ToHtml(const Arguments& args)
{
	HandleScope scope;
	Local<Object> obj =args[0]->ToObject();
	Local<External> wrap = Local<External>::Cast(obj->GetInternalField(0));
	boost::shared_ptr<KFM::Terminal::CScreen> ptr=*(static_cast<boost::shared_ptr<KFM::Terminal::CScreen> *>(wrap->Value()));
	ucs4_string ucs4=KFM::Terminal::htmlify_screen(*ptr);
	if(ucs4.size())
	{
		utf8_string html=ucs4_to_utf8(ucs4);
		return String::New(html.c_str(),html.size());
	}
	return String::New("",0);
}

extern "C" void
init(Handle<Object> target)
{
	HandleScope scope;
	NODE_SET_METHOD(target, "convert", ToHtml);
}
