package messaging

import (
	"crypto/tls"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net"
	"net/http"
	"net/url"
	"sync"
	"time"
)

//var pubnub *Pubnub

var (
	errRequestCanceledToResubscribe = errors.New("pubnub worker: request canceled to resubscribe")
	errRequestCanceledByUser        = errors.New("pubnub worker: request canceled by user")
	errRequestTimeout               = errors.New("pubnub worker: request timeout")
)

type requestCanceledReason int

const (
	canceledByUser requestCanceledReason = 1 << iota
	canceledToResubscribe
)

// Request worker is a requests pool that allows to track and close
// non-subscribe requests when needed
type requestWorker struct {

	// Worker name for logging purposes
	Name string

	// Timeout for the whole send-receive operation including body read
	Timeout time.Duration

	// Transport to use for all requests
	Transport   http.RoundTripper
	TransportMu sync.RWMutex

	CancelChs   map[string]chan requestCanceledReason
	CancelChsMu sync.RWMutex
	CancelChsWg sync.WaitGroup
	InfoLogger  *log.Logger
}

func newRequestWorker(name string, defaultTransport http.RoundTripper,
	roundTripTimeout uint16, logger *log.Logger) *requestWorker {

	logger.Printf("INFO: %s worker initialized", name)
	return &requestWorker{
		Name:       fmt.Sprintf("%s Worker", name),
		CancelChs:  make(map[string]chan requestCanceledReason),
		Timeout:    time.Duration(roundTripTimeout) * time.Second,
		Transport:  defaultTransport,
		InfoLogger: logger,
	}
}

func (w *requestWorker) Handle(req *http.Request) (
	resp []byte, statusCode int, err error) {

	w.InfoLogger.Printf("INFO: %s >>> %s", w.Name, req.URL.String())

	cancelCh := make(chan requestCanceledReason)
	w.CancelChsMu.Lock()
	w.CancelChs[req.URL.Opaque] = cancelCh
	w.CancelChsMu.Unlock()

	defer func() {
		w.CancelChsMu.Lock()
		delete(w.CancelChs, req.URL.Opaque)
		w.CancelChsMu.Unlock()
	}()

	cancelRequest := func() {
		if httpTransport, ok := w.Transport.(*http.Transport); ok {
			httpTransport.CancelRequest(req)
		}
	}

	requestCh := w.InvokeRequest(req)

	handleCanceledRequest := func() {
		<-requestCh
	}

	removeFromCancelers := func() {
		w.CancelChsWg.Done()
	}

	select {
	case <-time.After(w.Timeout):
		w.InfoLogger.Printf("INFO: %s: request timeout (%fs)", w.Name, w.Timeout.Seconds())
		go cancelRequest()
		go handleCanceledRequest()

		return nil, 0, errRequestTimeout
	case reason := <-cancelCh:
		w.InfoLogger.Printf("INFO: %s: request canceled by client: %s", w.Name, req.URL.Opaque)
		go cancelRequest()
		go removeFromCancelers()
		go handleCanceledRequest()

		var err error

		switch reason {
		case canceledByUser:
			err = errRequestCanceledByUser
		case canceledToResubscribe:
			err = errRequestCanceledToResubscribe
		}

		return nil, 0, err
	case resp := <-requestCh:
		return resp.Data, resp.StatusCode, resp.Error
	}
}

type workerResponse struct {
	Data       []byte
	StatusCode int
	Error      error
}

func (w *requestWorker) Client() *http.Client {
	w.TransportMu.Lock()
	defer w.TransportMu.Unlock()

	if w.Transport == nil {
		w.InfoLogger.Printf("INFO: %s: Initializing new transport", w.Name)
		transport := &http.Transport{
			TLSClientConfig: &tls.Config{InsecureSkipVerify: true},
			Dial: (&net.Dialer{
				Timeout: time.Duration(connectTimeout) * time.Second,
			}).Dial,
		}

		// TODO: fix this, this timeout is the same as in roundtrip canceller
		transport.ResponseHeaderTimeout = time.Duration(w.Timeout) * time.Second

		if proxyServerEnabled {
			proxyURL, err := url.Parse(fmt.Sprintf("http://%s:%s@%s:%d", proxyUser,
				proxyPassword, proxyServer, proxyPort))

			if err == nil {
				transport.Proxy = http.ProxyURL(proxyURL)
			} else {
				w.InfoLogger.Printf("ERROR: %s: Proxy connection error: %s", w.Name, err.Error())
			}
		}

		transport.MaxIdleConnsPerHost = maxIdleConnsPerHost
		w.Transport = transport
	}

	return &http.Client{
		Transport:     w.Transport,
		CheckRedirect: nil,
	}
}

func (w *requestWorker) InvokeRequest(req *http.Request) <-chan *workerResponse {
	resp := make(chan *workerResponse)

	go func() {
		var contents []byte

		rs := &workerResponse{
			Data:       nil,
			StatusCode: 0,
			Error:      nil,
		}

		httpClient := w.Client()
		response, err := httpClient.Do(req)

		if err == nil {
			defer response.Body.Close()
			bodyContents, e := ioutil.ReadAll(response.Body)

			if e == nil {
				contents = bodyContents
				//logInfof("%s <<< %s", w.Name, string(contents))
				w.InfoLogger.Printf("INFO: %s <<< %s %d", w.Name, string(contents), response.StatusCode)
				rs.Data = contents
				rs.StatusCode = response.StatusCode
			} else {
				rs.StatusCode = response.StatusCode
				rs.Error = e
			}
		} else {
			if response != nil {
				w.InfoLogger.Printf("ERROR: %s: server error: %s, response.StatusCode: %d", w.Name,
					err.Error(), response.StatusCode)

				rs.StatusCode = response.StatusCode
				rs.Error = err
			} else {
				w.InfoLogger.Printf("ERROR: %s: connection error: %s", w.Name, err.Error())

				rs.Error = err
			}
		}

		resp <- rs
	}()

	return resp
}

// Cancel pending requests and send message on errors channel
func (w *requestWorker) Cancel() {
	w.cancel(canceledByUser)
}

// Cancel pending requests and do not send message on errors channel
func (w *requestWorker) CancelToResubscribe() {
	w.cancel(canceledToResubscribe)
}

func (w *requestWorker) cancel(reason requestCanceledReason) {
	w.CancelChsMu.Lock()
	w.CancelChsWg.Add(len(w.CancelChs))
	w.CancelChsMu.Unlock()

	w.CancelChsMu.Lock()
	for _, ch := range w.CancelChs {
		if ch != nil {
			ch <- reason
		}
	}
	w.CancelChsMu.Unlock()

	// Block until all requests be closed
	w.CancelChsWg.Wait()

	w.CancelChsMu.Lock()
	w.InfoLogger.Printf("INFO: %s: all pending requests canceled\n", w.Name)
	w.CancelChsMu.Unlock()

	if trans, ok := w.Transport.(*http.Transport); ok {
		trans.CloseIdleConnections()
	}
}

// Provides worker transport. You can use it for transport modificatinos. To set
// your own transport, use associated setter
func (w *requestWorker) GetTransport() http.RoundTripper {
	return w.Transport
}
func (w *requestWorker) SetTransport(trans http.RoundTripper) {
	w.TransportMu.Lock()
	defer w.TransportMu.Unlock()

	w.InfoLogger.Printf("INFO: %s: New transport was set", w.Name)
	w.Transport = trans
}
