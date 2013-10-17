package moh

import (
	"log"
	"strings"
	"testing"
	"time"
)

const testWait = 10 * time.Millisecond

// testStartServer is a function invoked in a go statement to start the server.
// It sends the error to err channel since it cannot return it direcly because
// it is invoked in a go statement.
func testStartServer(s *CloseableServer, addr string, err chan error) {
	e := s.ListenAndServe(addr)
	if e != nil {
		err <- e
	} else {
		close(err)
	}
}

func TestCloseableServer(t *testing.T) {
	s1 := NewCloseableServer()
	s2 := NewCloseableServer()

	err1 := make(chan error)
	err2 := make(chan error)

	log.Println("Starting server 1")
	go testStartServer(s1, addr, err1)

	// Wait for first server to start listening
	select {
	case err := <-err1:
		// Could not start the server
		t.Error(err)
	case <-time.After(testWait):
		// No error in 10ms, server must be started successfully.
		log.Println("No error")
	}

	// Try to start second server, this must return an error
	// since the first server is already started.
	go testStartServer(s2, addr, err2)
	select {
	case err := <-err2:
		if !strings.Contains(err.Error(), "address already in use") {
			t.Error(err)
		} else {
			log.Println("Serve 2 could not be started as expected")
		}
	case <-time.After(testWait):
		t.Error("Did not get the error in allowed time period.")
	}

	log.Println("Closing server 1")
	s1.Close()
	<-time.After(testWait)
	// Must be closed here

	// Try to start second server again. It should start successfully since
	// the first server is closed now.
	go testStartServer(s2, addr, err2)
	select {
	case err := <-err2:
		t.Error(err)
	case <-time.After(testWait):
		// No error in 10ms, server must be started successfully.
		log.Println("No error")
	}

	// Do not leave the server open.
	s2.Close()
	<-time.After(testWait)
}
