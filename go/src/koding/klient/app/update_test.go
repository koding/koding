package app_test

import (
	"fmt"
	"net"
	"net/http"
	"net/url"
	"sync"
	"time"

	"koding/kites/tunnelproxy/discover/discovertest"
)

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
