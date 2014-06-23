package main

import (
	"fmt"
	"github.com/rcrowley/goagain"
	"log"
	"net"
	"syscall"
	"time"
)

func init() {
	log.SetFlags(log.Lmicroseconds | log.Lshortfile)
	log.SetPrefix(fmt.Sprintf("pid:%d ", syscall.Getpid()))
}

func main() {

	// Get the listener and ppid from the environment.  If this is successful,
	// this process is a child that's inheriting and open listener from ppid.
	l, ppid, err := goagain.GetEnvs()
	if nil != err {

		// Listen on a TCP or a UNIX domain socket (TCP here).
		l, err = net.Listen("tcp", "127.0.0.1:48879")
		if nil != err {
			log.Fatalln(err)
		}
		log.Println("listening on", l.Addr())

		// Accept connections in a new goroutine.
		go serve(l)

	} else {

		// Resume listening and accepting connections in a new goroutine.
		log.Println("resuming listening on", l.Addr())
		go serve(l)

		// Kill the parent, now that the child has started successfully.
		if err := goagain.KillParent(ppid); nil != err {
			log.Fatalln(err)
		}

	}

	// Block the main goroutine awaiting signals.
	if err := goagain.AwaitSignals(l); nil != err {
		log.Fatalln(err)
	}

	// Do whatever's necessary to ensure a graceful exit like waiting for
	// goroutines to terminate or a channel to become closed.

	// In this case, we'll simply stop listening and wait one second.
	if err := l.Close(); nil != err {
		log.Fatalln(err)
	}
	time.Sleep(1e9)

}

func serve(l net.Listener) {
	for {
		c, err := l.Accept()
		if nil != err {
			if goagain.IsErrClosing(err) {
				break
			}
			log.Fatalln(err)
		}
		c.Write([]byte("Hello, world!\n"))
		c.Close()
	}
}
