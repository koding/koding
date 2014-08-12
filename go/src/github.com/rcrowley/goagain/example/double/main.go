package main

import (
	"github.com/rcrowley/goagain"
	"fmt"
	"log"
	"net"
	"sync"
	"syscall"
	"time"
)

func init() {
	goagain.Strategy = goagain.Double
	log.SetFlags(log.Lmicroseconds | log.Lshortfile)
	log.SetPrefix(fmt.Sprintf("pid:%d ", syscall.Getpid()))
}

func main() {

	// Inherit a net.Listener from our parent process or listen anew.
	ch := make(chan struct{})
	wg := &sync.WaitGroup{}
	wg.Add(1)
	l, err := goagain.Listener()
	if nil != err {

		// Listen on a TCP or a UNIX domain socket (TCP here).
		l, err = net.Listen("tcp", "127.0.0.1:48879")
		if nil != err {
			log.Fatalln(err)
		}
		log.Println("listening on", l.Addr())

		// Accept connections in a new goroutine.
		go serve(l, ch, wg)

	} else {

		// Resume listening and accepting connections in a new goroutine.
		log.Println("resuming listening on", l.Addr())
		go serve(l, ch, wg)

		// If this is the child, send the parent SIGUSR2.  If this is the
		// parent, send the child SIGQUIT.
		if err := goagain.Kill(); nil != err {
			log.Fatalln(err)
		}

	}

	// Block the main goroutine awaiting signals.
	sig, err := goagain.Wait(l)
	if nil != err {
		log.Fatalln(err)
	}

	// Do whatever's necessary to ensure a graceful exit like waiting for
	// goroutines to terminate or a channel to become closed.
	//
	// In this case, we'll close the channel to signal the goroutine to stop
	// accepting connections and wait for the goroutine to exit.
	close(ch)
	wg.Wait()

	// If we received SIGUSR2, re-exec the parent process.
	if goagain.SIGUSR2 == sig {
		if err := goagain.Exec(l); nil != err {
			log.Fatalln(err)
		}
	}

}

// A very rude server that says hello and then closes your connection.
func serve(l net.Listener, ch chan struct{}, wg *sync.WaitGroup) {
	defer wg.Done()
	for {

		// Break out of the accept loop on the next iteration after the
		// process was signaled and our channel was closed.
		select {
		case <-ch:
			return
		default:
		}

		// Set a deadline so Accept doesn't block forever, which gives
		// us an opportunity to stop gracefully.
		l.(*net.TCPListener).SetDeadline(time.Now().Add(100e6))

		c, err := l.Accept()
		if nil != err {
			if goagain.IsErrClosing(err) {
				return
			}
			if err.(*net.OpError).Timeout() {
				continue
			}
			log.Fatalln(err)
		}
		c.Write([]byte("Hello, world!\n"))
		c.Close()
	}
}
