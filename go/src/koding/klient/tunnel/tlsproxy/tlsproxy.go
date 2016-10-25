package tlsproxy

import (
	"bufio"
	"bytes"
	"crypto/rand"
	"crypto/tls"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"runtime"
	"strings"
	"sync/atomic"
	"time"

	"github.com/koding/logging"

	"koding/klient/tunnel/tlsproxy/pem"
	"koding/tools/util"
)

var defaultLog = logging.NewCustom("tlsproxy", false)

// Init adds local route for pem.Hostname to 127.0.0.1 address.
func Init() error {
	if runtime.GOOS == "windows" {
		return errors.New("not implemented")
	}

	f, err := os.OpenFile("/etc/hosts", os.O_RDWR|os.O_APPEND, 0644)
	if err != nil {
		return err
	}

	scanner := bufio.NewScanner(f)
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())

		if len(fields) != 2 {
			continue
		}

		if fields[0] == "127.0.0.1" && fields[1] == pem.Hostname {
			f.Close()
			return nil
		}
	}

	if err := scanner.Err(); err != nil {
		return err
	}

	_, err = fmt.Fprintln(f, "127.0.0.1", pem.Hostname)
	return nonil(err, f.Close())
}

type Proxy struct {
	Log logging.Logger

	targetAddr string
	listener   net.Listener
	closed     uint32
	once       util.OnceSuccessful
}

func NewProxy(listenAddr, targetAddr string) (*Proxy, error) {
	cert, err := pem.Asset("fullchain.pem")
	if err != nil {
		return nil, err
	}

	key, err := pem.Asset("privkey.pem")
	if err != nil {
		return nil, err
	}

	crt, err := tls.X509KeyPair(cert, key)
	if err != nil {
		return nil, err
	}
	cfg := &tls.Config{
		Certificates: []tls.Certificate{crt},
		Rand:         rand.Reader,
		// Don't offer SSL3.
		MinVersion: tls.VersionTLS10,
		// Workaround TLS_FALLBACK_SCSV bug. For details see:
		// https://go-review.googlesource.com/#/c/1776/
		MaxVersion: tls.VersionTLS12,
	}
	listener, err := tls.Listen("tcp", listenAddr, cfg)
	if err != nil {
		return nil, err
	}

	p := &Proxy{
		Log:        defaultLog,
		targetAddr: targetAddr,
		listener:   listener,
	}

	go p.serve()

	return p, nil
}

func (p *Proxy) Close() error {
	if atomic.CompareAndSwapUint32(&p.closed, 0, 1) {
		return p.listener.Close()
	}

	return nil
}

func (p *Proxy) writeError(op string, err error, conn net.Conn) {
	body := bytes.NewBufferString(err.Error())
	resp := &http.Response{
		Status:        http.StatusText(http.StatusServiceUnavailable),
		StatusCode:    http.StatusServiceUnavailable,
		Proto:         "HTTP/1.1",
		ProtoMajor:    1,
		ProtoMinor:    1,
		Body:          ioutil.NopCloser(body),
		ContentLength: int64(body.Len()),
		Close:         true,
	}

	e := resp.Write(conn)

	if e != nil {
		p.Log.Error("%s: error %s (%s) and sending response back (%s)", conn.RemoteAddr(), op, err, e)
	} else {
		p.Log.Error("%s: error %s: %s", conn.RemoteAddr(), op, err)
	}
}

func (p *Proxy) serve() {
	for {
		conn, err := p.listener.Accept()
		if err != nil {
			if atomic.LoadUint32(&p.closed) != 1 {
				p.Log.Error("error listening for connections: %s", err)
			}

			return
		}

		go p.serveConn(conn)
	}
}

func (p *Proxy) serveConn(conn net.Conn) {
	req, err := http.ReadRequest(bufio.NewReader(conn))
	if err != nil {
		p.Log.Error("%s: error reading initial request: %s", conn.RemoteAddr(), err)

		conn.Close()
		return
	}

	rec := httptest.NewRecorder()

	if util.HandleCORS(rec, req) {
		resp := &http.Response{
			Status:     http.StatusText(rec.Code),
			StatusCode: rec.Code,
			Proto:      "HTTP/1.1",
			ProtoMajor: 1,
			ProtoMinor: 1,
			Header:     rec.HeaderMap,
			Close:      true,
		}

		if rec.Body != nil {
			resp.Body = ioutil.NopCloser(rec.Body)
			resp.ContentLength = int64(rec.Body.Len())
		}

		if err := resp.Write(conn); err != nil {
			p.Log.Error("%s: error writing CORS reply: %s", conn.RemoteAddr(), err)
		}

		conn.Close()
		return
	}

	target, err := net.DialTimeout("tcp", p.targetAddr, 30*time.Second)
	if err != nil {
		p.writeError("dialing target", err, conn)

		conn.Close()
		return
	}

	if err = req.Write(target); err != nil {
		p.writeError("writing initial request to target", err, conn)

		nonil(target.Close(), conn.Close())
		return
	}

	go io.Copy(conn, target)
	go io.Copy(target, conn)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}

	return nil
}
