#include <stdexcept>

#include "screen_wrap.hpp"



Handle<Value> ScreenCols(Local<String> property,const AccessorInfo &info)
{
  Local<Object> self = info.Holder();
  Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
  boost::shared_ptr<KFM::Terminal::CScreen> ptr=*static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(wrap->Value());
  return Integer::New(ptr->numCols());
}

Handle<Value> ScreenRows(Local<String> property,const AccessorInfo &info)
{
  Local<Object> self = info.Holder();
  Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
  boost::shared_ptr<KFM::Terminal::CScreen> ptr=*static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(wrap->Value());
  return Integer::New(ptr->numRows());
}

Handle<Value> ScreenRow(const Arguments& args)
{
  Local<Object> self = args.Holder();
  Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
  int row=args[0]->Int32Value();
  boost::shared_ptr<KFM::Terminal::CScreen> ptr=*static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(wrap->Value());
  std::string str;

  for(int i=0;i<ptr->numCols();i++)
  {
    str+=ptr->getCell(row,i).c;
  }
   
  return String::New(str.c_str(),str.size());
}

Handle<Value> ScreenCursor(const Arguments &args)
{
  Local<Object> self = args.Holder();
  Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
  boost::shared_ptr<KFM::Terminal::CScreen> ptr=*static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(wrap->Value());
  Local<Object> obj=Object::New();
  obj->Set(String::New("row"),Integer::New(ptr->getCursorRow()));
  obj->Set(String::New("col"),Integer::New(ptr->getCursorCol()));
  return obj;
}


Handle<Value> ScreenCel(const Arguments& args)
{
  Local<Object> self = args.Holder();
  Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
  boost::shared_ptr<KFM::Terminal::CScreen> ptr=*static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(wrap->Value());
  return String::New((char const*)&(ptr->getCell(args[1]->Int32Value(),args[2]->Int32Value()).c),1);
}

Handle<ObjectTemplate> ScreenTemplate()
{
  Handle<ObjectTemplate> result = ObjectTemplate::New();
  result->SetAccessor(String::New("cols"), ScreenCols);
  result->SetAccessor(String::New("rows"), ScreenRows);
  result->Set("row", FunctionTemplate::New(ScreenRow));
  result->Set("cel", FunctionTemplate::New(ScreenCel));
  result->Set("cursor",FunctionTemplate::New(ScreenCursor));
  result->SetInternalFieldCount(1);
  return Persistent<ObjectTemplate>::New(result);
}

void ScreenDestructor( Persistent<Value> obj,void* param )
{
  delete static_cast<boost::shared_ptr<KFM::Terminal::CScreen> * >(param);
  obj.Dispose();
  obj.Clear();
}


v8::Handle<v8::Value> WrapScreen(boost::shared_ptr<KFM::Terminal::CScreen> &screen)
{
  static Handle<ObjectTemplate> screen_template = ScreenTemplate();
  Persistent<Object> result = v8::Persistent<v8::Object>::New(screen_template->NewInstance());
  boost::shared_ptr<KFM::Terminal::CScreen> *ptr=new boost::shared_ptr<KFM::Terminal::CScreen>(screen);
  result.MakeWeak(ptr,&ScreenDestructor);
  result->SetInternalField(0, External::New(ptr));
  return result;
}

