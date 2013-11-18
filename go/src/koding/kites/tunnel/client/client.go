package main

import (
	"bufio"
	"fmt"
	"koding/kites/tunnel/join"
	"koding/kites/tunnel/protocol"
	"log"
	"net"
	"net/http"
	"os"
)

var serverAddr = "127.0.0.1:7000"
var localAddr = "127.0.0.1:5000"
var registerPath = "_kdtunnel_"

func init() {
	log.SetOutput(os.Stdout)
	log.SetPrefix("tunnel-client ")
	log.SetFlags(log.Lmicroseconds)
}

func main() {
	remoteConn, err := net.Dial("tcp", serverAddr)
	if err != nil {
		log.Println("dial remote err: %s", err)
		return
	}
	defer remoteConn.Close()

	// _, err = remoteConn.Write([]byte("fatih"))
	// fmt.Println(err)

	remoteAddr := fmt.Sprintf("http://%s%s", serverAddr, protocol.RegisterPath)
	req, err := http.NewRequest("CONNECT", remoteAddr, nil)
	if err != nil {
		log.Println("connect err", err)
		return
	}

	req.Header.Set("Username", "fatih")
	req.Write(remoteConn)

	resp, err := http.ReadResponse(bufio.NewReader(remoteConn), req)
	if err != nil {
		log.Println("read response err", resp)
		return
	}
	resp.Body.Close()

	if resp.StatusCode != 200 && resp.Status != protocol.Connected {
		err = fmt.Errorf("Non-200 response from proxy server: %s", resp.Status)
		return
	}
	fmt.Println(resp.Status)

	// buffer := make([]byte, 256)
	// log.Println("waiting for read")

	// _, err = remoteConn.Read(buffer)
	// log.Println("got buffer", string(buffer))

	localConn, err := net.Dial("tcp", localAddr)
	if err != nil {
		log.Printf("dial local err: %s\n", err)
		return
	}
	defer localConn.Close()

	join.Join(localConn, remoteConn)

}
