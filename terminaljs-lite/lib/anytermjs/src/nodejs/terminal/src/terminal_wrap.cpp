#include <cstdlib>


#include <string>
#include <string.h>

#include "terminal_wrap.hpp"


struct ScreenCopier
{
    boost::shared_ptr<KFM::Terminal::CScreen> &screen;

    ScreenCopier(boost::shared_ptr<KFM::Terminal::CScreen> &scr) : screen(scr)
    {}
    void copy(const KFM::Terminal::CScreen & scr)
    {
        screen->copy(const_cast<KFM::Terminal::CScreen &>(scr)) ;
    }
    void operator()(const KFM::Terminal::CScreen & scr)
    {
        copy(scr);
    }
};

TerminalEngine::TerminalEngine() : mWorker(boost::bind(&TerminalEngine::run,this))
{}

void TerminalEngine::run()
{
    boost::asio::io_service::work work(mIOService);
    mIOService.run();
}

boost::asio::io_service & TerminalEngine::getIOService()
{
    return mIOService;
}



TerminalWrap::TerminalWrap(const char *cmd,size_t rows,size_t cols) : 
        mTerminal(TerminalWrap::Engine.getIOService(),cmd,rows,cols)
        , mScreen(new KFM::Terminal::CScreen(rows,cols)) 
        , mReadyCallbackData(Undefined()), mErrorCallbackData(Undefined()), mIsDead(false)
{
    InitEventHandlers();
}


void TerminalWrap::InitEventHandlers()
{
    ev_async_init(&mReadyNotifier, TerminalWrap::ReadyCallback);
    mReadyNotifier.data = this;
    ev_async_start(EV_DEFAULT_UC_ & mReadyNotifier);
    ev_async_init(&mErrorNotifier, TerminalWrap::ErrorCallback);
    mErrorNotifier.data = this;
    ev_async_start(EV_DEFAULT_UC_ & mErrorNotifier);
}
TerminalWrap::~TerminalWrap()
{
    destroy();   
}
void TerminalWrap::destroy()
{
    try
    {
        if(!mIsDead)
        {
            mTerminal.kill();
            ev_async_stop(EV_DEFAULT_UC_ & mReadyNotifier);
            ev_async_stop(EV_DEFAULT_UC_ & mErrorNotifier);
            mIsDead=true;
        }
    }
    catch(...)
    {}
}
void TerminalWrap::ReadyNotifier()
{
    ev_async_send(EV_DEFAULT_UC_ & mReadyNotifier);
}

void TerminalWrap::ReadyCallback(EV_P_ ev_async *w, int revents)
{
    TerminalWrap *term = static_cast<TerminalWrap *> (w->data);
    HandleScope scope;
 
    if (term->mReadyCallback->IsFunction())
    {
        v8::Handle<v8::Value> args[]={term->GetScreen(),term->mReadyCallbackData};
        term->mReadyCallback->Call(term->mReadyCallback, 2,args);
    }
}

void TerminalWrap::ErrorNotifier()
{
    ev_async_send(EV_DEFAULT_UC_ & mErrorNotifier);
}

void TerminalWrap::ErrorCallback(EV_P_ ev_async *w, int revents)
{
    TerminalWrap *term = static_cast<TerminalWrap *> (w->data);
    HandleScope scope;
    if (term->mErrorCallback->IsFunction())
    {
        term->mErrorCallback->Call(term->mErrorCallback, 1, &term->mErrorCallbackData);
    }
}

void TerminalWrap::Initialize(Handle<Object> target)
{
    HandleScope scope;
    Handle<FunctionTemplate> t = FunctionTemplate::New(New);
    mConstructorTemplate = Persistent<FunctionTemplate>::New(t);
    mConstructorTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    mConstructorTemplate->SetClassName(String::NewSymbol("Terminal"));
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "write", JSSend);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "getScreen", JSGetScreen);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "setScreenSize", JSSetScreenSize);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "getScreenSize", JSGetScreenSize);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "error", JSError);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"on",JSBindEvent);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"emit",JSEmit);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"kill",JSKill);

    target->Set(String::NewSymbol("Terminal"), mConstructorTemplate->GetFunction());
}

Handle<Value> TerminalWrap::New(const Arguments &args)
{
    try
    {
        if ((args.Length() >= 3) && (args[0]->IsString() && args[1]->IsInt32() && args[2]->IsInt32()))
        {
            String::Utf8Value cmd(args[0]->ToString());
            TerminalWrap *term = new TerminalWrap(*cmd, args[1]->Int32Value(), args[2]->Int32Value());
            term->Wrap(args.This());
            return args.This();
        }
        else
        {
            return ThrowException(Exception::Error(String::New("Terminal::new error : Invalid arguments, expected new(cmd,rows,cols)")));
        }
    }
    catch (std::exception &e)
    {
        std::string error="Terminal::new error, exception: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalWrap::JSSend(const Arguments &args)
{
     if((args.Length()<1)||(!args[0]->IsString()))
     {
         return ThrowException(Exception::Error(String::New("Terminal::send error: Invalid arguments, expected send(cmd)")));
     }
     TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
     return term->Send(args[0]->ToString());
}
Handle<Value> TerminalWrap::Send(Handle<String> cmd)
{
    try
    {    
        if (mTerminal.hasError())
        {
            return ThrowException(Exception::Error(String::New("Terminal::send error, IO Error")));
        }
        String::Utf8Value utf8(cmd);
        mTerminal.write(*utf8, cmd->Utf8Length());
    }
    catch(std::exception &e)
    {
        std::string error="Terminal::send error: exception : ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    
    return Undefined();
}

Handle<Value> TerminalWrap::JSGetScreen(const Arguments& args)
{
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->GetScreen();
}

Handle<Value> TerminalWrap::GetScreen()
{
    try
    {        
        if (mTerminal.hasError())
        {
            return ThrowException(Exception::Error(String::New("Terminal::getScreen error: IO Error")));
        }
        ScreenCopier copier(mScreen);
        mTerminal.parseScreen(boost::bind(&ScreenCopier::copy,&copier,_1));
        return WrapScreen(mScreen);
    }
    catch(std::exception &e)
    {
        std::string error="Terminal::getScreen error: exception : ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalWrap::JSSetScreenSize(const Arguments &args)
{
    if((args.Length()<2)||(!args[0]->IsInt32())||(!args[1]->IsInt32()))
    {
       return ThrowException(Exception::Error(String::New("Terminal::setScreenSize error: Invalid arguments, expected setScreenSize(integer,integer)")));
    }
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->SetScreenSize(args[0]->ToInt32(),args[1]->ToInt32());
}

Handle<Value> TerminalWrap::SetScreenSize(Handle<Int32> rows,Handle<Int32> cols)
{
    try
    { 
        if (mTerminal.hasError())
        {
            return ThrowException(Exception::Error(String::New("Terminal::setScreenSize error: IO Error")));
        }
        mTerminal.resize(rows->Value(),cols->Value());
    }
    catch(std::exception &e)
    {
        std::string error="Terminal::setScreenSize error: exception : ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalWrap::JSGetScreenSize(const Arguments& args)
{
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->GetScreenSize();
}

Handle<Value> TerminalWrap::GetScreenSize()
{
    try
    {      
        if (mTerminal.hasError())
        {
            return ThrowException(Exception::Error(String::New("Terminal::getScreenSize error: IO Error")));
        }
        std::pair<int, int> res = mTerminal.getSize();
        Handle<Object> obj = Object::New();
        obj->Set(String::New("rows"), Integer::New(res.first));
        obj->Set(String::New("cols"), Integer::New(res.second));
        return obj;
    }
    catch(std::exception &e)
    {
        std::string error="Terminal::getScreenSize error: exception : ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalWrap::JSError(const Arguments &args)
{
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->Error();
}

Handle<Value> TerminalWrap::Error()
{   
    return Boolean::New(mTerminal.hasError());
}


Handle<Value> TerminalWrap::JSBindEvent(const Arguments& args)
{
    if((args.Length()<2)||(!args[0]->IsString())||(!args[1]->IsFunction()))
    {
        return ThrowException(Exception::Error(String::New("Terminal::bind error, Invalid arguments, expected bind(event,callback)")));
    }
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->BindEvent(args[0]->ToString(),Handle<Function>::Cast(args[1]));
    
}

Handle<Value> TerminalWrap::BindEvent(Handle<String> event,Handle<Function> callback)
{
    String::Utf8Value val(event);
    if(!strcmp((const char *)*val,"data"))
    {
        mReadyCallback = Persistent<Function>::New(callback);
        mTerminal.bindScreenReady(boost::bind(&TerminalWrap::ReadyNotifier, this));
    }
    else if(!strcmp((const char *)*val,"error"))
    {
        mErrorCallback = Persistent<Function>::New(callback);
        mTerminal.bindError(boost::bind(&TerminalWrap::ErrorNotifier, this));
    }
    return Undefined();
}

Handle<Value> TerminalWrap::JSEmit(const Arguments& args)
{
    if((args.Length()<2)||(!args[0]->IsString()))
    {
        return ThrowException(Exception::Error(String::New("Terminal::emit error, Invalid arguments, expected emit(event,value)")));
    }
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->Emit(args[0]->ToString(),args[1]);
}

Handle<Value> TerminalWrap::Emit(Handle<String> event,Handle<Value> data)
{
    String::Utf8Value val(event);
    if(!strcmp((const char *)*val,"data"))
    {
        mReadyCallbackData=Persistent<Value>::New(data);
    }
    else if(!strcmp((const char *)*val,"error"))
    {
        mErrorCallbackData=Persistent<Value>::New(data);
    }
    return Undefined();
}

Handle<Value> TerminalWrap::Kill()
{
    destroy();
    return Undefined();
}

Handle<Value> TerminalWrap::JSKill(const Arguments& args)
{
    TerminalWrap *term = ObjectWrap::Unwrap<TerminalWrap > (args.This());
    return term->Kill();
}

Persistent<FunctionTemplate> TerminalWrap::mConstructorTemplate;
TerminalEngine TerminalWrap::Engine;
