package app_test

import (
	"errors"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"sync"
	"testing"
	"time"

	"github.com/koding/logging"

	"koding/kites/tunnelproxy/discover/discovertest"
	"koding/klient/app"
	"koding/klient/remote/mount"
)

func TestUpdater(t *testing.T) {
	const timeout = 250 * time.Millisecond

	events := make(chan *mount.Event)
	defer close(events)

	s := StartUpdateServer()

	u := &app.Updater{
		Endpoint:    s.URL().String(),
		Interval:    50 * time.Millisecond,
		Log:         logging.NewCustom("updater", true),
		MountEvents: events,
	}

	go u.Run()

	if err := s.WaitForLatestReq(timeout); err != nil {
		t.Fatal(err)
	}

	// Send a mouting event and ensure no
	// update attempt was made afterwards.
	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventMounting,
	}

	// From this point update server will mark every latest request as illegal.
	s.Enable(false)

	if err := s.WaitForLatestReq(timeout); err == nil {
		t.Fatal("expected to timeout waiting for latest with disabled autoupdates")
	}

	// Send event that mouting succeeded, still no update requests expected.
	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventMounted,
	}

	if err := s.WaitForLatestReq(timeout); err == nil {
		t.Fatal("expected to timeout waiting for latest with disabled autoupdates")
	}

	// Send unmount event, but for different path that was previously reported
	// as mounted - this event should be ignored, autoupdates still disabled.
	events <- &mount.Event{
		Path: "/pathX",
		Type: mount.EventUnmounted,
	}

	// Only confirmed umount enables autoupdate, since unmounting
	// can traisition to failed - this event also does not enable autoupdates.
	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventUnmounting,
	}

	if err := s.WaitForLatestReq(timeout); err == nil {
		t.Fatal("expected to timeout waiting for latest with disabled autoupdates")
	}

	// Send unmount event for previous mount and expect autoupdates to turn on.
	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventUnmounted,
	}

	s.Enable(true)

	if err := s.WaitForLatestReq(timeout); err != nil {
		t.Fatal(err)
	}

	// Send mounting event, expect autoupdates to turn off, send the mount
	// was failed and expect the autoupdates to turn on again.
	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventMounting,
	}

	s.Enable(false)

	if err := s.WaitForLatestReq(timeout); err == nil {
		t.Fatal("expected to timeout waiting for latest with disabled autoupdates")
	}

	events <- &mount.Event{
		Path: "/path1",
		Type: mount.EventMounting,
		Err:  errors.New("mount failed"),
	}

	s.Enable(true)

	if err := s.WaitForLatestReq(timeout); err != nil {
		t.Fatal(err)
	}

	// Ensure no update request was made while the autoupdates
	// were expected to be disabled.
	if err := s.Err(); err != nil {
		t.Fatal(err)
	}
}

type UpdateServer struct {
	mu          sync.Mutex
	lis         net.Listener
	enabled     bool
	reqEnabled  []*http.Request
	reqDisabled []*http.Request
}

func StartUpdateServer() *UpdateServer {
	l, err := net.Listen("tcp", ":0")
	if err != nil {
		panic(err)
	}

	wl := discovertest.NewListener(l)

	u := &UpdateServer{
		lis:     wl,
		enabled: true,
	}

	go http.Serve(wl, u)

	wl.Wait()

	return u
}

func (u *UpdateServer) ServeHTTP(w http.ResponseWriter, req *http.Request) {
	u.mu.Lock()
	if u.enabled {
		u.reqEnabled = append(u.reqEnabled, req)
	} else {
		u.reqDisabled = append(u.reqDisabled, req)
	}
	u.mu.Unlock()

	w.WriteHeader(http.StatusBadRequest)
}

func (u *UpdateServer) WaitForLatestReq(timeout time.Duration) error {
	t := time.After(timeout)

	n := u.LatestReqNum()

	for {
		select {
		case <-t:
			return fmt.Errorf("timed out waiting for latest req after %s", timeout)
		default:
			if u.LatestReqNum() > n {
				return nil
			}

			time.Sleep(50 * time.Millisecond)
		}
	}
}

func (u *UpdateServer) LatestReqNum() int {
	u.mu.Lock()
	defer u.mu.Unlock()

	return len(u.reqEnabled)
}

func (u *UpdateServer) Err() error {
	u.mu.Lock()
	defer u.mu.Unlock()

	if len(u.reqDisabled) != 0 {
		return fmt.Errorf("%d latest requests was served when the updater was disabled", len(u.reqDisabled))
	}

	return nil
}

func (u *UpdateServer) Enable(b bool) {
	u.mu.Lock()
	u.enabled = b
	u.mu.Unlock()
}

func (u *UpdateServer) URL() *url.URL {
	return &url.URL{
		Scheme: "http",
		Host:   u.lis.Addr().String(),
		Path:   "/",
	}
}
