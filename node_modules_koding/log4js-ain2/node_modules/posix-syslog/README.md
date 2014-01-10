posix-syslog
============

Interface to Syslog via the old, traditional posix syscalls. It just works.[1]

### Example

```javascript

var syslog = require("posix-syslog");

syslog.open("myApp");

syslog.log("Wow, this is going to syslog!");
syslog.crit("HELP! A Critical Message!");

syslog.close();

```

The syslog is also automatically opened (though with default configuration) if
you simply call to one of the logging functions without opening it manually.

### Installation

	npm install posix-syslog

### Logging

The basic log functions available are defined by posix-syslog's masks:

```javascript
syslog.emerg()
syslog.alert()
syslog.crit()
syslog.err()
syslog.warning()
syslog.notice()
syslog.info()
syslog.debug()
```

### Configuration & Options

You can pass options into `syslog.open`. These options follow the same format as
the [`posix.openlog` function.](https://github.com/melor/node-posix#posixopenlogidentity-options-facility)

You may want to configure the posix-syslog module to mirror what it sends to syslog
to your STDOUT/STDERR. This is done via console.log/error/warn/info, and mapped
to the syslog mask you specify. Simply set `syslog.mirror` to true, and the
syslog output will be mirrored to the console.

### Licence (BSD)

Copyright (c) 2013, Christopher Giffard
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

*	Redistributions of source code must retain the above copyright notice, this list
	of conditions and the following disclaimer.
*	Redistributions in binary form must reproduce the above copyright notice, this
	list of conditions and the following disclaimer in the documentation and/or
	other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

### Fineprint

[1] Provided node posix isn't busted on your computer. And no, sorry, I can't
help you fix it.