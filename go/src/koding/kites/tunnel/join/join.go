package join

import (
	"io"
	"log"
	"net"
	"sync"
)

func Join(local, remote net.Conn) {
	var wg sync.WaitGroup

	pipe := func(to, from net.Conn) {
		defer local.Close()
		defer remote.Close()
		defer wg.Done()

		_, err := io.Copy(to, from)
		log.Printf("copying from %s to %s, err: %s\n", from.RemoteAddr().String(), to.RemoteAddr().String(), err)
	}

	wg.Add(2)
	go pipe(local, remote)
	go pipe(remote, local)
	wg.Wait()

	log.Println("join finished")
	return
}
