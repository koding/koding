package main

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"koding/virt"
	"net"
	"strings"
	"time"
)

func main() {
	listener, err := net.Listen("tcp", ":80")
	if err != nil {
		fmt.Println(err)
		return
	}
	for {
		conn, err := listener.Accept()
		if err != nil {
			continue
		}
		go handleConnection(conn)
	}
}

func handleConnection(source net.Conn) {
	defer source.Close()

	buffer := bytes.NewBuffer(nil)
	r := bufio.NewReaderSize(io.TeeReader(source, buffer), 128)

	_, err := r.ReadString('\n') // ignored
	if err != nil {
		return
	}

	var name string
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
			name = strings.TrimSpace(strings.SplitN(parts[1], ".", 2)[0])
			break
		}
	}

	vm, err := virt.FromUsername(name)
	if err != nil {
		source.Write([]byte("HTTP/1.1 307 Temporary Redirect\r\nLocation: http://www.koding.com/notfound.html\r\n\r\n"))
		return
	}

	c := make(chan *net.TCPConn)
	go func() {
		target, _ := net.DialTCP("tcp", nil, &net.TCPAddr{vm.IP, 80})
		c <- target
	}()

	var target *net.TCPConn
	select {
	case target = <-c:
	case <-time.After(5 * time.Second):
	}

	if target == nil {
		source.Write([]byte("HTTP/1.1 307 Temporary Redirect\r\nLocation: http://www.koding.com/notactive.html\r\n\r\n"))
		return
	}

	target.Write(buffer.Bytes())
	go io.Copy(target, source)
	io.Copy(source, target)
}
