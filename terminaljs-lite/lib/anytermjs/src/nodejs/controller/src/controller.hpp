/* 
 * File:   controller.hpp
 * Author: vic
 *
 * Created on January 3, 2012, 10:39 PM
 */

#ifndef CONTROLLER_HPP
#define	CONTROLLER_HPP

#include <node.h>
#include <node_buffer.h>
#include <map>
#include <string>
#include <boost/random/random_device.hpp>
#include <boost/random/uniform_int_distribution.hpp>
#include <boost/asio.hpp>

#include "terminal_wrap.hpp"

using namespace v8;
using namespace node;

struct TerminalSession
{
    TerminalWrap terminal;
    int last_update;
    TerminalSession(const char *cmd,size_t rows,size_t cols);
    void touch();
};

class TerminalController : public ObjectWrap
{
private:
    std::map<std::string,boost::shared_ptr<TerminalSession> > mCache;
    int mTimeout;
    boost::asio::deadline_timer mTimer;
    static Persistent<FunctionTemplate> mConstructorTemplate;
public:
    TerminalController(int timeout);
    ~TerminalController();
    static void Initialize(Handle<Object> target);
    static Handle<Value> New(const Arguments &args);
    static Handle<Value> Create(const Arguments &args);
    static Handle<Value> Close(const Arguments &args);
    static Handle<Value> CloseAll(const Arguments &args);
    static Handle<Value> Send(const Arguments &args);
    static Handle<Value> Bind(const Arguments &args);
    static Handle<Value> Emit(const Arguments &args);
    static Handle<Value> GetScreen(const Arguments &args);
    static Handle<Value> GetScreenSize(const Arguments &args);
    static Handle<Value> SetScreenSize(const Arguments &args);
protected:
    boost::shared_ptr<TerminalSession> & FindSession(Handle<String> id);
    void CleanTimedout(const boost::system::error_code&);
    
    
};

#endif	/* CONTROLLER_HPP */

