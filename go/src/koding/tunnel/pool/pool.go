// Package pool implements a pool of net.Conn interfaces to manage and reuse them.
package pool

import (
	"errors"
	"log"
	"net"
)

// Factory is a function to create new connections.
type Factory func() (net.Conn, error)

// Pool allows you to use a pool of resources.
type Pool struct {
	conns   chan net.Conn
	factory Factory
}

// New returns a new pool with an initial capacity and maximum capacity.
// Factory is used when initial capacity is greater then zero to fill the
// pool.
func New(initialCap, maxCap int, factory Factory) *Pool {
	if initialCap <= 0 || maxCap <= 0 || initialCap > maxCap {
		panic("Invalid/out of range capacity")
	}

	p := &Pool{
		conns:   make(chan net.Conn, maxCap),
		factory: factory,
	}

	log.Println("going to create initial connections", initialCap)
	for i := 0; i < initialCap; i++ {
		conn, err := factory()
		if err != nil {
			log.Println("WARNING: factory is not able to fill the pool", err)
		}

		p.conns <- conn
	}

	log.Println("number of pools", p.UsedCapacity(), p.MaximumCapacity())

	return p
}

// Get returns a new connection from the pool. After using the connection it
// should be put back via the Put() method. If there is no new connection
// available in the pool, a new connection will be created via the Factory()
// method until it reached the maximumum capacity of the pool.
func (p *Pool) Get() (net.Conn, error) {
	select {
	case conn := <-p.conns:
		log.Println("get number of pools", p.UsedCapacity(), p.MaximumCapacity())
		return conn, nil
	default:
		if p.UsedCapacity() == p.MaximumCapacity() {
			return nil, errors.New("maximum capacaity reached. no free conn available. put some to be used")
		}

		return p.factory()
	}
}

// Put puts a new connection into the pull
func (p *Pool) Put(conn net.Conn) {
	select {
	case p.conns <- conn:
		log.Println("put number of pools", p.UsedCapacity(), p.MaximumCapacity())
	default:
		panic("attempt to put into a full pool")
	}

}

// Close closes all the pools connections
func (p *Pool) Close() { close(p.conns) }

// MaximumCapacity returns the maximum capacity of the pool
func (p *Pool) MaximumCapacity() int { return cap(p.conns) }

// UsedCapacity returns the used capacity of the pool.
func (p *Pool) UsedCapacity() int { return len(p.conns) }
