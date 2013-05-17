package fastproxy

import (
	"bufio"
	"bytes"
	"crypto/tls"
	"io"
	"net"
	"net/http"
	"strings"
)

type HTTPRequest struct {
	Host   string
	Cookie string
	source net.Conn
	buffer *bytes.Buffer
}

func ListenHTTP(privateAddr *net.TCPAddr, cert *tls.Certificate, fetchCookie bool, handler func(*HTTPRequest)) error {
	return listen(privateAddr, cert, func(source net.Conn) {
		defer source.Close()
		req := HTTPRequest{
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

			key := strings.ToLower(parts[0])
			if key == "host" {
				req.Host = strings.TrimSpace(parts[1])
			} else if fetchCookie && key == "cookie" {
				req.Cookie = strings.TrimSpace(parts[1])
			}

			if req.Host != "" && (!fetchCookie || req.Cookie != "") {
				break
			}
		}

		handler(&req)
	})
}

func (req *HTTPRequest) Relay(addr *net.TCPAddr) error {
	target, err := connect(addr)
	if err != nil {
		return err
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

func (req *HTTPRequest) Respond(response *http.Response) error {
	return response.Write(req.source)
}

func (req *HTTPRequest) Redirect(url string) error {
	return req.Respond(&http.Response{
		StatusCode: http.StatusTemporaryRedirect,
		ProtoMajor: 1,
		ProtoMinor: 1,
		Header: http.Header{
			"Location": []string{url},
		},
	})
}
