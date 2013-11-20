package tunnel

import (
	"io"
	"net"
)

func join(local, remote net.Conn) {
	done := make(chan bool, 2)

	copy := func(dst io.Writer, src io.Reader) {
		// don't care about errors here
		io.Copy(dst, src)
		done <- true
	}

	go copy(local, remote)
	go copy(remote, local)

	<-done
}
