#include "controller.hpp"
#include <signal.h>
#include <iostream>

extern "C" void
init(Handle<Object> target)
{
        signal(SIGPIPE,SIG_IGN);
	HandleScope scope;
	TerminalController::Initialize(target);
 	  
}
