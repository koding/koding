package test

import (
	"log"
	"sync"
	"sync/atomic"
)

type runState int32

const (
	stateIdle runState = iota
	stateRunning
	stateCancelling
)

type basicRunner struct {
	Steps []Step

	cancelCh chan struct{}
	doneCh   chan struct{}
	state    runState
	l        sync.Mutex
}

func (b *basicRunner) Run(state AzureStateBag) {
	b.l.Lock()
	if b.state != stateIdle {
		panic("already running")
	}

	// Seed the random name generator
	reseed()

	cancelCh := make(chan struct{})
	doneCh := make(chan struct{})
	b.cancelCh = cancelCh
	b.doneCh = doneCh
	b.state = stateRunning
	b.l.Unlock()

	defer func() {
		b.l.Lock()
		b.cancelCh = nil
		b.doneCh = nil
		b.state = stateIdle
		close(doneCh)
		b.l.Unlock()
	}()

	// This goroutine listens for cancels and puts the StateCancelled key
	// as quickly as possible into the state bag to mark it.
	go func() {
		select {
		case <-cancelCh:
			// Flag cancel and wait for finish
			state.Put(StateCancelled, true)
			<-doneCh
		case <-doneCh:
		}
	}()

	for _, step := range b.Steps {
		// We also check for cancellation here since we can't be sure
		// the goroutine that is running to set it actually ran.
		if runState(atomic.LoadInt32((*int32)(&b.state))) == stateCancelling {
			state.Put(StateCancelled, true)
			break
		}

		action := step.Run(state)
		defer step.Cleanup(state)

		if _, ok := state.GetOk(StateCancelled); ok {
			break
		}

		if action == Halt {
			log.Println("[INFO] Halt requested by current step")
			state.Put(StateHalted, true)
			break
		}
	}
}

func (b *basicRunner) Cancel() {
	b.l.Lock()
	switch b.state {
	case stateIdle:
		// Not running, so Cancel is... done.
		b.l.Unlock()
		return
	case stateRunning:
		// Running, so mark that we cancelled and set the state
		close(b.cancelCh)
		b.state = stateCancelling
		fallthrough
	case stateCancelling:
		// Already cancelling, so just wait until we're done
		ch := b.doneCh
		b.l.Unlock()
		<-ch
	}
}
