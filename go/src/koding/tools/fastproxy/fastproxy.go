package fastproxy

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"errors"
	"io"
	"net"
	"strings"
	"time"
)

type Request struct {
	Host   string
	source net.Conn
	buffer *bytes.Buffer
}

func Listen(laddr *net.TCPAddr, cert *tls.Certificate, handler func(Request)) error {
	var listener net.Listener
	listener, err := net.ListenTCP("tcp", laddr)
	if err != nil {
		return err
	}

	if cert != nil {
		listener = tls.NewListener(listener, &tls.Config{
			NextProtos:   []string{"http/1.1"},
			Certificates: []tls.Certificate{*cert},
		})
	}

	for {
		source, err := listener.Accept()
		if err != nil {
			continue
		}

		go func() {
			defer source.Close()
			req := Request{
				source: source,
				buffer: bytes.NewBuffer(nil),
			}

			r := bufio.NewReaderSize(io.TeeReader(source, req.buffer), 128)

			_, err := r.ReadString('\n') // ignored
			if err != nil {
				return
			}

			for {
				line, err := r.ReadString('\n')
				if err != nil {
					return
				}
				parts := strings.SplitN(line, ":", 2)
				if len(parts) != 2 {
					return
				}
				if parts[0] == "Host" {
					req.Host = strings.TrimSpace(parts[1])
					break
				}
			}

			handler(req)
		}()
	}

	return nil
}

func (req Request) Relay(addr *net.TCPAddr) error {
	var target *net.TCPConn
	targetChan := make(chan *net.TCPConn)
	errChan := make(chan error)
	go func() {
		target, err := net.DialTCP("tcp", nil, addr)
		if err != nil {
			errChan <- err
		}
		targetChan <- target
	}()

	select {
	case target = <-targetChan:
		// continue
	case err := <-errChan:
		return err
	case <-time.After(5 * time.Second):
		go func() { // cleanup function
			select {
			case target := <-targetChan:
				target.Close()
			case <-errChan:
			}
		}()
		return errors.New("Timeout")
	}

	target.Write(req.buffer.Bytes())
	go func() {
		io.Copy(target, req.source)
		target.CloseWrite()
	}()
	io.Copy(req.source, target)
	target.CloseRead()

	return nil
}

func (req Request) Redirect(url string) {
	req.source.Write([]byte("HTTP/1.1 307 Temporary Redirect\r\nLocation: " + url + "\r\n\r\n"))
}
