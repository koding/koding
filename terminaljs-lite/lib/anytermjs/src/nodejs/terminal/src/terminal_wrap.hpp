#ifndef TERMINAL_OBJECT_HPP
#define TERMINAL_OBJECT_HPP
#include <node.h>
#include <node_buffer.h>
#include <boost/thread.hpp>
#include "terminal.hpp"
#include "screen.hpp"
#include "screen_wrap.hpp"


using namespace v8;
using namespace node;

class TerminalEngine
{
    boost::thread mWorker;
    boost::asio::io_service mIOService;
public:
    TerminalEngine();
    boost::asio::io_service & getIOService();
protected:
    void run();
    
};


class TerminalWrap : public ObjectWrap {
public:
    static TerminalEngine Engine;
private:
    static Persistent<FunctionTemplate> mConstructorTemplate;
    
    
    boost::shared_ptr<KFM::Terminal::CScreen> mScreen;
    KFM::Terminal::CTerminal mTerminal;

    ev_async mReadyNotifier;
    ev_async mErrorNotifier;
    Persistent<Function> mReadyCallback;
    Persistent<Function> mErrorCallback;
    Handle<Value> mErrorCallbackData;
    Handle<Value> mReadyCallbackData;
    bool mIsDead;
    
public:
    TerminalWrap(const char *cmd,size_t rows,size_t cols);
    ~TerminalWrap();
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(const Arguments &args);
    static Handle<Value> JSBindEvent(const Arguments &args);
    Handle<Value> BindEvent(Handle<String> event,Handle<Function> callback);
    static Handle<Value> JSSend(const Arguments &args);
    Handle<Value> Send(Handle<String> str);
    static Handle<Value> JSGetScreen(const Arguments &args);
    Handle<Value> GetScreen();
    static Handle<Value> JSSetScreenSize(const Arguments &args);
    Handle<Value> SetScreenSize(Handle<Int32> rows,Handle<Int32> cols);
    static Handle<Value> JSGetScreenSize(const Arguments &args);
    Handle<Value> GetScreenSize();
    static Handle<Value> JSError(const Arguments &args);
    Handle<Value> Error();
    static Handle<Value> JSEmit(const Arguments &args);
    Handle<Value> Emit(Handle<String> event,Handle<Value> data);
    Handle<Value> Kill();
    static Handle<Value> JSKill(const Arguments &args);
    
protected:
    void InitEventHandlers();
    static void ReadyCallback(EV_P_ ev_async *w, int revents);
    void ReadyNotifier();
    static void ErrorCallback(EV_P_ ev_async *w, int revents);
    void ErrorNotifier();
    inline void destroy();

};
#endif
