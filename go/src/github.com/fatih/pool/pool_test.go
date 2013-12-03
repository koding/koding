package pool

import (
	"log"
	"net"
	"sync"
	"testing"
	"time"
)

var (
	InitialCap = 5
	MaximumCap = 30
	network    = "tcp"
	address    = "127.0.0.1:7777"
	factory    = func() (net.Conn, error) { return net.Dial(network, address) }
)

func init() {
	// used for factory function
	go simpleTCPServer()
	time.Sleep(time.Millisecond * 300) // wait until tcp server has been settled
}

func TestNew(t *testing.T) {
	_, err := newPool()
	if err != nil {
		t.Errorf("New error: %s", err)
	}
}

func TestPool_Get(t *testing.T) {
	p, _ := newPool()
	defer p.Close()

	_, err := p.Get()
	if err != nil {
		t.Errorf("Get error: %s", err)
	}

	// after one get, current capacity should be lowered by one.
	if p.CurrentCapacity() != (InitialCap - 1) {
		t.Errorf("Get error. Expecting %d, got %d",
			(InitialCap - 1), p.CurrentCapacity())
	}

	// get them all
	var wg sync.WaitGroup
	for i := 0; i < (InitialCap - 1); i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := p.Get()
			if err != nil {
				t.Errorf("Get error: %s", err)
			}
		}()
	}
	wg.Wait()

	if p.CurrentCapacity() != 0 {
		t.Errorf("Get error. Expecting %d, got %d",
			(InitialCap - 1), p.CurrentCapacity())
	}

	_, err = p.Get()
	if err != nil {
		t.Errorf("Get error: %s", err)
	}
}

func TestPool_Put(t *testing.T) {
	p, _ := newPool()
	defer p.Close()

	for i := 0; i < MaximumCap; i++ {
		conn, _ := p.factory()
		p.Put(conn)
	}

	if p.MaximumCapacity() != MaximumCap {
		t.Errorf("Put error. Expecting %d, got %d",
			1, p.CurrentCapacity())
	}

	err := p.Put(nil)
	if err == nil {
		t.Errorf("Put error. A nil conn should be rejected")
	}

	conn, _ := p.factory()
	err = p.Put(conn) // try to put into a full pool
	if err == nil {
		t.Errorf("Put error. Put into a full pool should return an error")
	}

}

func TestPool_MaximumCapacity(t *testing.T) {
	p, _ := newPool()
	defer p.Close()

	if p.MaximumCapacity() != MaximumCap {
		t.Errorf("MaximumCapacity error. Expecting %d, got %d",
			MaximumCap, p.CurrentCapacity())
	}
}

func TestPool_UsedCapacity(t *testing.T) {
	p, _ := newPool()
	defer p.Close()

	if p.CurrentCapacity() != InitialCap {
		t.Errorf("InitialCap error. Expecting %d, got %d",
			InitialCap, p.CurrentCapacity())
	}
}

func TestPool_Close(t *testing.T) {
	p, _ := newPool()
	conn, _ := p.factory() // to be used with put

	// now close it and test all cases we are expecting.
	p.Close()

	if p.conns != nil {
		t.Errorf("Close error, conns channel should be nil")
	}

	if p.factory != nil {
		t.Errorf("Close error, factory should be nil")
	}

	_, err := p.Get()
	if err == nil {
		t.Errorf("Close error, get conn should return an error")
	}

	err = p.Put(conn)
	if conn == nil {
		t.Errorf("Close error, put conn should return an error")
	}

	if p.CurrentCapacity() != 0 {
		t.Errorf("Close error used capacity. Expecting 0, got %d", p.CurrentCapacity())
	}

	if p.MaximumCapacity() != 0 {
		t.Errorf("Close error max capacity. Expecting 0, got %d", p.MaximumCapacity())
	}
}

func TestPoolConcurrent(t *testing.T) {
	p, _ := newPool()
	pipe := make(chan net.Conn, 0)

	go func() {
		p.Close()
	}()

	for i := 0; i < MaximumCap; i++ {
		go func() {
			conn, _ := p.Get()

			pipe <- conn
		}()

		go func() {
			conn := <-pipe
			p.Put(conn)
		}()
	}
}

func TestPoolConcurrent2(t *testing.T) {
	p, _ := newPool()

	for i := 0; i < MaximumCap; i++ {
		conn, _ := p.factory()
		p.Put(conn)
	}

	for i := 0; i < MaximumCap; i++ {
		go func() {
			p.Get()
		}()
	}

	p.Close()
}

func newPool() (*Pool, error) { return New(InitialCap, MaximumCap, factory) }

func simpleTCPServer() {
	l, err := net.Listen(network, address)
	if err != nil {
		log.Fatal(err)
	}
	defer l.Close()

	for {
		conn, err := l.Accept()
		if err != nil {
			log.Fatal(err)
		}

		buffer := make([]byte, 256)
		conn.Read(buffer)
	}
}
