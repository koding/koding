// Copyright (c) 2015 Marin Atanasov Nikolov <dnaeon@gmail.com>
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer
//    in this position and unchanged.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE AUTHOR(S) ``AS IS'' AND ANY EXPRESS OR
// IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL THE AUTHOR(S) BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
// NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
// THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

package recorder

import (
	"bufio"
	"bytes"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"net/http/httptest"
	"net/http/httputil"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/pubnub/go-vcr/cassette"
)

type RecorderMode int

// Recorder states
const (
	ModeRecording RecorderMode = iota
	ModeReplaying
)

type Recorder struct {
	// Operating mode of the recorder
	mode RecorderMode

	// HTTP server used to mock requests
	server *httptest.Server

	// Cassette used by the recorder
	cassette *cassette.Cassette

	// Transport that can be used by clients to inject
	Transport *http.Transport

	stopMu    sync.Mutex
	matcherMu sync.Mutex

	wg *sync.WaitGroup
}

// Proxies client requests to their original destination
func requestHandler(r *http.Request, c *cassette.Cassette, mode RecorderMode) (
	*cassette.Interaction, error) {

	// Return interaction from cassette if in replay mode
	if mode == ModeReplaying {
		return c.GetInteraction(r)
	}

	c.RequestStated(r.URL.String())

	// Copy the original request, so we can read the form values
	reqBytes, err := httputil.DumpRequestOut(r, true)
	if err != nil {
		return nil, err
	}

	reqBuffer := bytes.NewBuffer(reqBytes)
	copiedReq, err := http.ReadRequest(bufio.NewReader(reqBuffer))
	if err != nil {
		return nil, err
	}

	err = copiedReq.ParseForm()
	if err != nil {
		return nil, err
	}

	// Perform client request to it's original
	// destination and record interactions
	body := ioutil.NopCloser(r.Body)
	req, err := http.NewRequest(r.Method, r.URL.String(), body)
	if err != nil {
		return nil, err
	}

	req.Header = r.Header
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}

	// Record the interaction and add it to the cassette
	reqBody, err := ioutil.ReadAll(req.Body)
	if err != nil {
		return nil, err
	}

	respBody, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	c.RequestFinished(r.URL.String())

	// Add interaction to cassette
	interaction := &cassette.Interaction{
		Request: cassette.Request{
			Body:    string(reqBody),
			Form:    copiedReq.PostForm,
			Headers: req.Header,
			URL:     req.URL.String(),
			Method:  req.Method,
		},
		Response: cassette.Response{
			Body:    string(respBody),
			Headers: resp.Header,
			Status:  resp.Status,
			Code:    resp.StatusCode,
		},
	}
	c.AddInteraction(interaction)

	return interaction, nil
}

// Creates a new recorder
func New(cassetteName string) (*Recorder, error) {
	var mode RecorderMode
	var c *cassette.Cassette
	var wg sync.WaitGroup
	cassetteFile := fmt.Sprintf("%s.yaml", cassetteName)

	// Depending on whether the cassette file exists or not we
	// either create a new empty cassette or load from file
	if _, err := os.Stat(cassetteFile); os.IsNotExist(err) {
		// Create new cassette and enter in recording mode
		c = cassette.New(cassetteName)
		mode = ModeRecording
	} else {
		// Load cassette from file and enter replay mode
		c, err = cassette.Load(cassetteName)
		if err != nil {
			return nil, err
		}
		mode = ModeReplaying
		wg.Add(len(c.UnclosedRequests))
	}

	rec := &Recorder{
		mode:     mode,
		cassette: c,
		wg:       &wg,
	}

	doneRequests := make(map[string]struct{})
	var doneRequestMu sync.RWMutex

	// Handler for client requests
	handler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {

		if rec.mode == ModeReplaying && c.HasRequest(r.URL.String()) {
			doneRequestMu.RLock()
			_, duplicate := doneRequests[r.URL.String()]
			doneRequestMu.RUnlock()

			if duplicate != true {
				doneRequestMu.Lock()
				doneRequests[r.URL.String()] = struct{}{}
				doneRequestMu.Unlock()
			}

			cn, ok := w.(http.CloseNotifier)
			if !ok {
				log.Fatal("don't support CloseNotifier")
			}

			<-cn.CloseNotify()
			if duplicate != true {
				wg.Done()
			}

			return
		}

		interaction, err := requestHandler(r, c, mode)

		if err != nil {
			panic(fmt.Errorf("Failed to process request for URL:\n%s\n%s", r.URL, err))
		}

		w.WriteHeader(interaction.Response.Code)
		body := strings.TrimSuffix(interaction.Response.Body, "\n")
		fmt.Fprintln(w, body)
	})

	// HTTP server used to mock requests
	rec.server = httptest.NewServer(handler)

	// A proxy function which routes all requests through our HTTP server
	// Can be used by clients to inject into their own transports
	proxyUrl, err := url.Parse(rec.server.URL)
	if err != nil {
		return nil, err
	}

	// A transport which can be used by clients to inject
	rec.Transport = &http.Transport{
		Proxy: http.ProxyURL(proxyUrl),
	}

	return rec, nil
}

// Setter for custom matcher
func (r *Recorder) UseMatcher(matcher cassette.Matcher) {
	r.cassette.SetMatcher(matcher)
}

// Recorder mode getter
func (r *Recorder) Mode() RecorderMode {
	return r.mode
}

type keepAliveServer interface {
	SetKeepAlivesEnabled(bool)
}

// Stops the recorder
func (r *Recorder) Stop() error {
	if r.mode == ModeReplaying {
		waitChannel := make(chan struct{})

		go func() {
			r.wg.Wait()
			waitChannel <- struct{}{}
		}()

		select {
		case <-waitChannel:
		case <-time.After(5 * time.Second):
			// Extra subscribe calls dosne't invoked, and it's ok
		}
	}

	r.stopMu.Lock()
	r.server.Listener.Close()

	var srv interface{}
	srv = r.server.Config
	if s, ok := srv.(keepAliveServer); ok {
		s.SetKeepAlivesEnabled(false)
	}

	r.server.CloseClientConnections()
	r.Transport = nil
	r.stopMu.Unlock()

	if r.mode == ModeRecording {
		if err := r.cassette.Save(); err != nil {
			return err
		}
	}

	return nil
}
