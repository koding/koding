package klient

import (
	"errors"
	"fmt"
	"io/ioutil"
	"net/http"
	"time"
)

// kiteHTTPResponse is the response we expect from a Kites http server. Used to
// verify an http server is indeed kite, and not something else.
const kiteHTTPResponse = "Welcome to SockJS!\n"

type KlientService struct {
	// An http address that we expect klient to be running on.
	KlientAddress string

	// The maxmimum number of attempts to wait for klient to be stopped/started.
	MaxAttempts int

	// The time between checks of klient running/stopped.
	PauseInterval time.Duration

	// Service is the underlying interface the the operating systems init service.
	Service interface {
		Stop() error
		Start() error
	}
}

// IsKlientRunning does a quick check against klient's http server
// to verify that it is running. It does *not* check the auth or tcp
// connection, it *just* attempts to verify that klient is running.
func (s *KlientService) IsKlientRunning() bool {
	res, err := http.Get(s.KlientAddress)
	if res != nil {
		defer res.Body.Close()
	}

	// If there was an error even talking to Klient, something is wrong.
	if err != nil {
		return false
	}

	// It should be safe to ignore any errors dumping the response data,
	// since we just want to check the data itself. Handling the error
	// might aid with debugging any problems though.
	resData, _ := ioutil.ReadAll(res.Body)
	if string(resData) != kiteHTTPResponse {
		return false
	}

	return true
}

// Start calls for the service to start klient, and waits for klient to be both
// running and dialable. The length of time it waits is based on this structs
// configuration.
func (s *KlientService) Start() error {
	// If the service fails to start klient, there's not much we can do.
	if err := s.Service.Start(); err != nil {
		return err
	}

	return s.WaitUntilStarted()
}

// Stop calls for the service to stop klient, and waits for klient to be stopped.
// The length of time it waits is based on this structs configuration.
func (s *KlientService) Stop() error {
	// If the service fails to start klient, there's not much we can do.
	if err := s.Service.Stop(); err != nil {
		return err
	}

	return s.WaitUntilStopped()
}

// StartWithoutWait just calls for the service to start klient, without waiting
// for klient to be explicitly started. The service itself likely won't wait either.
func (s *KlientService) StartWithoutWait() error {
	return s.Service.Start()
}

// StopWithoutWait just calls for the service to stop klient, without waiting
// for klient to be explicitly stopped. The service itself likely won't wait either.
func (s *KlientService) StopWithoutWait() error {
	return s.Service.Stop()
}

// WaitUntilStarted repeatedly checks to see if Klient is running, and waiting until
// it is no longer running.
func (s *KlientService) WaitUntilStarted() error {
	// Wait for klient
	for i := 0; i < s.MaxAttempts; i++ {
		fmt.Println("Waiting for klient....", s.KlientAddress)

		if s.IsKlientRunning() {
			return nil
		}

		time.Sleep(s.PauseInterval)
	}

	return errors.New("Klient failed to start in the expected time")
}

// WaitUntilStopped repeatedly checks to see if Klient is running, and waiting until
// it is no longer running.
func (s *KlientService) WaitUntilStopped() error {
	// Wait for klient
	for i := 0; i < s.MaxAttempts; i++ {
		if !s.IsKlientRunning() {
			return nil
		}

		time.Sleep(s.PauseInterval)
	}

	return errors.New("Klient failed to stop in the expected time")
}
