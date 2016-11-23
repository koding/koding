## go-sh
[![wercker status](https://app.wercker.com/status/009acbd4f00ccc6de7e2554e12a50d84/s "wercker status")](https://app.wercker.com/project/bykey/009acbd4f00ccc6de7e2554e12a50d84)
[![Go Walker](http://gowalker.org/api/v1/badge)](http://gowalker.org/github.com/codeskyblue/go-sh)

*for the better grow of this package. some change may influence the old users, the old-code has tag: v0.1*

install: `go get github.com/codeskyblue/go-sh`

Pipe Example:

	package main

	import "github.com/codeskyblue/go-sh"

	func main() {
		sh.Command("echo", "hello\tworld").Command("cut", "-f2").Run()
	}

I like os/exec, so this golang package go-sh, is very like os/exec. But it really have some better experience than os/exec.

There are some features, listed bellow.

* keep the variable environment (like export)
* alias support (like alias in shell)
* remember current dir
* pipe command
* shell build-in command test
* timeout support

Example is always important. I will show you how to use it.

	sh: echo hello
	go: sh.Command("echo", "hello").Run()

	sh: export BUILD_ID=123
	go: s = sh.NewSession().SetEnv("BUILD_ID", "123")

	sh: alias ll='ls -l'
	go: s = sh.NewSession().Alias('ll', 'ls', '-l')

	sh: (cd /; pwd)
	go: sh.Command("pwd", sh.Dir("/")).Run()

	sh: test -d data || mkdir data
	go: if ! sh.Test("dir", "data") { sh.Command("mkdir", "data").Run() }
	
	sh: echo hello world | awk '{print $1}'
	go: sh.Command("echo", "hello", "world").Command("awk", "{print $1}").Run()

	sh: msg=$(echo hi)
	go: msg, err := sh.Command("echo", "hi").Output()

	sh(in ubuntu): timeout 1s sleep 3
	go: c := sh.Command("sleep", "3"); c.Start(); c.WaitTimeout(time.Seocnd) # default SIGKILL
	go: out, err := sh.Command("sleep", "3").SetTimeout(time.Second).Output() # set session timeout and get output)

If you need to keep env and dir, it is better to create a session

	session := sh.NewSession()
	session.SetEnv("BUILD_ID", "123")
	session.SetDir("/")
	# then call cmd
	session.Command("echo", "hello").Run()
	# set ShowCMD to true for easily debug
	session.ShowCmd = true

for more information, it better to see docs.
[![Go Walker](http://gowalker.org/api/v1/badge)](http://gowalker.org/github.com/shxsun/go-sh)

### contribute
If you love this project, star it which will encourage the coder. pull requests are welcomed, if you want to add some new fetures.

support the author: [alipay](https://me.alipay.com/goskyblue)

### thanks
this project is based on <http://github.com/codegangsta/inject>. thanks for the author.

# the reason to use golang shell
So what is go-sh. Sometimes we need to write some shell scripts, but shell scripts is not good at cross platform, but golang is good at that. Is there a good way to use golang to write scripts like shell? Use go-sh we can do it now.
