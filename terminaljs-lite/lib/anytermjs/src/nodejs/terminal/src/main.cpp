#define _KFM_LOG_ENABLED_ 1
#include "log.hpp"
#include "terminal.hpp"
#include "terminal_wrap.hpp"
#include <signal.h>
#include <iostream>



    

extern "C" void
init(Handle<Object> target)
{
        HandleScope scope;
        KFM_LOG_INIT_FILE("terminal.log");
        signal(SIGPIPE,SIG_IGN);
        TerminalWrap::Initialize(target);
 	  
}
