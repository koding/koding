package fastproxy

import (
	"crypto/tls"
	"errors"
	"net"
	"time"
)

func listen(privateAddr *net.TCPAddr, cert *tls.Certificate, handler func(source net.Conn)) error {
	var listener net.Listener
	listener, err := net.ListenTCP("tcp", privateAddr)
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

		go handler(source)
	}

	return nil
}

func connect(addr *net.TCPAddr) (*net.TCPConn, error) {
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
		return nil, err
	case <-time.After(5 * time.Second):
		go func() { // cleanup function
			select {
			case target := <-targetChan:
				target.Close()
			case <-errChan:
			}
		}()
		return nil, errors.New("Timeout")
	}

	return target, nil
}
