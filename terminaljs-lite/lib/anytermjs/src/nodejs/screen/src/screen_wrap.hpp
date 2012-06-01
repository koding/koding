#ifndef SCREEN_HPP_NODEJS
#define SCREEN_HPP_NODEJS
#include <cstdlib>
#include <node.h>
#include <node_buffer.h>

#include <string>
#include "screen.hpp"

#include <boost/shared_ptr.hpp>

using namespace v8;
using namespace node;

Handle<Value> ScreenCols(Local<String> property,const AccessorInfo &info);

Handle<Value> ScreenRows(Local<String> property,const AccessorInfo &info);

Handle<Value> ScreenRow(const Arguments& args);

Handle<Value> ScreenCel(const Arguments& args);

Handle<Value> ScreenCursor(const Arguments &args);

Handle<ObjectTemplate> ScreenTemplate();

void ScreenDestructor( Persistent<Value> obj,void* param );

v8::Handle<v8::Value> WrapScreen(boost::shared_ptr<KFM::Terminal::CScreen> &p);

#endif

