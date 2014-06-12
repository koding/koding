package pool

import (
	"errors"
	"sync"

	"github.com/koding/logging"
)

// Machine defines a instance which can be queried with the given id. The id
// should uniquely identified and associated with a machine.
type Machine struct {
	Id uint
}

type Factory interface {
	Create() (*Machine, error)
	Destroy(uint) error
}

type Pool struct {
	mu       sync.Mutex
	machines chan *Machine
	log      logging.Logger

	factory Factory
}

// InitializeCaching should be called only once. It creates
func NewPool(initialCap, maxCap int, factory Factory) (*Pool, error) {
	if initialCap <= 0 || maxCap <= 0 || initialCap > maxCap {
		return nil, errors.New("invalid capacity settings")
	}

	if factory == nil {
		return nil, errors.New("factory function is not given.")
	}

	p := &Pool{
		machines: make(chan *Machine, maxCap),
		factory:  factory,
	}

	for i := 0; i < initialCap; i++ {
		go func() {
			machine, err := p.factory.Create()
			if err != nil {
				p.log.Error("filling cache channel: %s", err.Error())
			}

			p.Put(machine)
		}()
	}

	return p, nil
}

// Put puts the machine into the cache pool. If the pool is full,
// it factory is invoked to destroy the passed machine.
func (p *Pool) Put(machine *Machine) error {
	select {
	case p.machines <- machine:
		return nil
	default:
		go p.factory.Destroy(machine.Id)
		return errors.New("cache is already full, deleting previous machine")
	}
}

// Get fetchs a machine from the cache pool. After a succesfull fetch another
// goroutine is going to create a cached machine to fill the cache pool. If
// there is no machine in the cache pool a new machine is created and returned.
func (p *Pool) Get() (*Machine, error) {
	select {
	case machine := <-p.machines:
		if machine == nil {
			return nil, errors.New("cache channel is closed")
		}

		// create and put another cached machine into the channel after we get
		// one, let's try that that channel is always be filled.
		go func() {
			newMachine, err := p.factory.Create()
			if err != nil {
				p.log.Error("pool get, creating new machine err: %s", err.Error())
				return
			}

			if err := p.Put(newMachine); err != nil {
				p.log.Error("pool get, putting new machine err: %s", err.Error())
			}
		}()

		return machine, nil
	default:
		return p.factory.Create()
	}
}
