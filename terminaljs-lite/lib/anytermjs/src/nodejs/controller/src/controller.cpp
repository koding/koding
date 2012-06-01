#include <fstream>
#include <boost/make_shared.hpp>

#include "controller.hpp"


TerminalSession::TerminalSession(const char *cmd ,size_t rows,size_t cols) : 
        terminal(cmd,rows,cols),last_update(time(NULL))
{
   
}

void TerminalSession::touch()
{
    last_update=time(NULL);
}

TerminalController::TerminalController(int timeout) : mTimeout(timeout) , mTimer(TerminalWrap::Engine.getIOService(),boost::posix_time::seconds(timeout))
{
    mTimer.async_wait(boost::bind(&TerminalController::CleanTimedout,this,boost::asio::placeholders::error));
}

TerminalController::~TerminalController()
{}

void TerminalController::Initialize(Handle<Object> target)
{
    HandleScope scope;
    Handle<FunctionTemplate> t = FunctionTemplate::New(New);
    mConstructorTemplate = Persistent<FunctionTemplate>::New(t);
    mConstructorTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    mConstructorTemplate->SetClassName(String::NewSymbol("TerminalController"));
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "send", Send);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "getScreen", GetScreen);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "setScreenSize", SetScreenSize);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate, "getScreenSize", GetScreenSize);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"bind",Bind);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"emit",Emit);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"close",Close);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"closeAll",CloseAll);
    NODE_SET_PROTOTYPE_METHOD(mConstructorTemplate,"create",Create);

    target->Set(String::NewSymbol("TerminalController"), mConstructorTemplate->GetFunction());
}

Handle<Value> TerminalController::New(const Arguments &args)
{
    try
    {
        if((args.Length() <1)||(!args[0]->IsInt32()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::New error: Invalid arguments, expected new(timeout)")));
        }
        TerminalController *controller = new TerminalController(args[0]->Int32Value());
        controller->Wrap(args.This());
        return args.This();
    }
    catch (std::exception &e)
    {
        std::string error="Create controller error: Exception: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalController::Create(const Arguments& args)
{
    try
    {
        if ((args.Length() >= 3) && (args[0]->IsString() && args[1]->IsInt32() && args[2]->IsInt32()))
        {
            TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
            String::Utf8Value cmd(args[0]->ToString());
            std::ifstream random("/proc/sys/kernel/random/uuid");
            std::string id;
            random>>id;
            boost::shared_ptr<TerminalSession> session(new TerminalSession(*cmd, args[1]->Int32Value(), args[2]->Int32Value()));
            if((args.Length()>=4)&&args[3]->IsObject())
            {
                Local<Object> settings=args[3]->ToObject();
                Local<String> key=String::New("screenDidChange");
                Local<Value> callback=settings->Get(key);
                if(callback->IsFunction())
                {
                    session->terminal.BindEvent(key,Handle<Function>::Cast(callback));
                }
                
                key=String::New("error");
                callback=settings->Get(key);
                if(callback->IsFunction())
                {
                    session->terminal.BindEvent(key,Handle<Function>::Cast(callback));
                }
                key=String::New("screenDidChangeEmit");
                if(settings->Has(key))
                {
                    session->terminal.Emit(String::New("screenDidChange"),settings->Get(key));
                }
                
                key=String::New("errorEmit");
                if(settings->Has(key))
                {
                    session->terminal.Emit(String::New("error"),settings->Get(key));
                }
            }
            controller->mCache.insert(std::pair<std::string,boost::shared_ptr<TerminalSession> >(id,boost::make_shared<TerminalSession>(*cmd, args[1]->Int32Value(), args[2]->Int32Value())));
            return v8::String::New(id.c_str(),id.length());
        }

    }
    catch (std::exception &e)
    {
        std::string error="TerminalController::Create error: Exception: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return v8::ThrowException(v8::Exception::Error(v8::String::New("TerminalController::Create error: Invalid arguments, needed create(cmd,rows,cols)")));
}
Handle<Value> TerminalController::Close(const Arguments &args)
{
    try
    {
        if((args.Length()<1)||(!args[0]->IsString()))
        {
            return v8::ThrowException(v8::Exception::Error(v8::String::New("TerminalController::Close error: Invalid arguments, needed close(id)")));
        }
        String::Utf8Value arg0(args[0]->ToString());
        std::string id=*arg0;
        TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
        std::map<std::string,boost::shared_ptr<TerminalSession> >::iterator it;
        it=controller->mCache.find(id);
        if(it!=controller->mCache.end())
        {
            controller->mCache.erase(it);
        }

    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::Close error: Exception: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}
Handle<Value> TerminalController::CloseAll(const Arguments& args)
{
    try
    {
        TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
        controller->mCache.clear();
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::CloseAll error: Exception: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

boost::shared_ptr<TerminalSession> & TerminalController::FindSession(Handle<String> val)
{
    String::Utf8Value utf(val);
    std::string id=*utf;
    std::map<std::string,boost::shared_ptr<TerminalSession> >::iterator it=mCache.find(id);
    if(it==mCache.end())
    {
       throw std::runtime_error("Unable to find session");
    }
    it->second->touch();
    return it->second;
}

Handle<Value> TerminalController::Send(const Arguments &args)
{
    try
    {
        if((args.Length()<2)||(!args[0]->IsString()||!args[1]->IsString()))
        {
            return v8::ThrowException(v8::Exception::Error(v8::String::New("TerminalController::Send error: Invalid arguments, needed send(id,cmd)")));
        }
        TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.Send(args[1]->ToString());
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::Send error:  ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalController::Bind(const Arguments& args)
{
    try
    {
        if((args.Length()<3)||(!args[0]->IsString())||(!args[1]->IsString())||(!args[2]->IsFunction()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::Bind error: Invalid arguments, needed bind(id,event,callback)")));
        }
        
        TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.BindEvent(args[1]->ToString(),Handle<Function>::Cast(args[2]));
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::Bind error: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
}

Handle<Value> TerminalController::Emit(const Arguments& args)
{
    try
    {
        if((args.Length()<3)||(!args[0]->IsString())||(!args[1]->IsString()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::Emit error: Invalid arguments, expected emit(id,event,data)")));
        }
        TerminalController *controller = ObjectWrap::Unwrap<TerminalController > (args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.Emit(args[1]->ToString(),Handle<Function>::Cast(args[2]));
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::Emit error: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
    return Undefined();
    
}


Handle<Value> TerminalController::GetScreen(const Arguments& args)
{
    try
    {
        if((args.Length()<1)||(!args[0]->IsString()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::GetScreen error, Invalid arguments, expected getScreen(id)")));
        }
        TerminalController *controller=ObjectWrap::Unwrap<TerminalController>(args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.GetScreen();
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::GetScreen error: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
}

Handle<Value> TerminalController::GetScreenSize(const Arguments &args)
{
    try
    {
        if((args.Length()<1)||(!args[0]->IsString()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::GetScreenSize error, Invalid arguments, expected getScreenSize(id)")));
        }
        TerminalController *controller=ObjectWrap::Unwrap<TerminalController>(args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.GetScreenSize();
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::GetScreenSize error: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
}

Handle<Value> TerminalController::SetScreenSize(const Arguments& args)
{
    try
    {
        if((args.Length()<3)||(!args[0]->IsString())||(!args[1]->IsInt32())||(!args[2]->IsInt32()))
        {
            return ThrowException(Exception::Error(String::New("TerminalController::SetScreenSize error, Invalid arguments, expected setScreenSize(id,rows,cols)")));
        }
        TerminalController *controller=ObjectWrap::Unwrap<TerminalController>(args.This());
        boost::shared_ptr<TerminalSession> & session=controller->FindSession(args[0]->ToString());
        return session->terminal.SetScreenSize(args[1]->ToInt32(),args[2]->ToInt32());
    }
    catch(std::exception &e)
    {
        std::string error="TerminalController::SetScreenSize error: ";
        error+=e.what();
        return ThrowException(Exception::Error(String::New(error.c_str(),error.length())));
    }
}

void TerminalController::CleanTimedout(const boost::system::error_code &ec)
{
    if(ec)
    {
        if(ec!=boost::asio::error::operation_aborted)
        {
            std::string error="TerminalController::Timer error: ";
            error+=ec.message();
            throw new std::runtime_error(error.c_str());
        }
    }
    else
    {
    
        //cleanup timed-outed sessions
        int timeout=time(NULL)-2*mTimeout;
        for(std::map<std::string,boost::shared_ptr<TerminalSession> >::iterator it=mCache.begin();it!=mCache.end();++it)
        {
            if(it->second->last_update<timeout)
            {
                mCache.erase(it);
            }
        }

        mTimer.expires_from_now( boost::posix_time::seconds(mTimeout));
        mTimer.async_wait(boost::bind(&TerminalController::CleanTimedout,this,boost::asio::placeholders::error));
    }
    
}

Persistent<FunctionTemplate> TerminalController::mConstructorTemplate;