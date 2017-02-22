package rsync

import (
	"context"
	"fmt"
	"os/exec"
	"path/filepath"
	"sync"

	"koding/klient/machine/client"
	"koding/klient/machine/index"
	msync "koding/klient/machine/mount/sync"
)

// Builder is a factory for rsync-based synchronization objects.
type Builder struct{}

// Build satisfies msync.Builder interface. It produces Rsync objects from a
// given options if rsync executable is present in $PATH.
func (Builder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	if _, err := exec.LookPath("rsync"); err != nil {
		return nil, fmt.Errorf("rsync: %v", err)
	}

	return NewRsync(opts.Mount.RemotePath, opts.CacheDir,
		opts.Username, opts.AddrFunc, opts.IndexSyncFunc), nil
}

// Event is a rsync synchronization object that utilizes rsync executable.
type Event struct {
	ev     *msync.Event
	parent *Rsync
}

// Exec satisfies msync.Execer interface. It executes rsync executable with
// arguments available to sync stored change.
func (e *Event) Exec() error {
	if !e.ev.Valid() {
		return nil
	}
	defer e.ev.Done()

	change := e.ev.Change()
	err := e.parent.Cmd(e.ev.Context(), e.makeArgs(change)...).Run()
	e.parent.indexSync(change)

	return err
}

// makeArgs transforms provided index change to rsync executable arguments.
func (e *Event) makeArgs(c *index.Change) []string {

	from := filepath.Join(e.parent.local, c.Path())
	to := filepath.Join(e.parent.remote, c.Path())

	meta := c.Meta()
	if meta&index.ChangeMetaRemote != 0 {
		from, to = to, from // Swap sync directions.
	}

	return []string{"a", "b", "c"}
}

// String implements fmt.Stringer interface. It pretty prints internal event.
func (e *Event) String() string {
	return e.ev.String() + " - " + "rsynced"
}

// Rsync uses rsync(1) file-copying tool to provide synchronization between
// remote and local files.
type Rsync struct {
	Cmd func(ctx context.Context, args ...string) *exec.Cmd // Comand factory.

	remote    string                 // remote directory root.
	local     string                 // local directory root.
	user      string                 // remote username.
	dynAddr   client.DynamicAddrFunc // address of connected machine.
	indexSync msync.IndexSyncFunc    // callback used to update index.

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewRsync creates a new Rsync synchronization object.
func NewRsync(remote, local, user string, dynAddr client.DynamicAddrFunc, indexSync msync.IndexSyncFunc) *Rsync {
	return &Rsync{
		Cmd: func(ctx context.Context, args ...string) *exec.Cmd {
			return exec.CommandContext(ctx, "rsync", args...)
		},

		remote:    remote,
		local:     local,
		user:      user,
		dynAddr:   dynAddr,
		indexSync: indexSync,
		stopC:     make(chan struct{}),
	}
}

// ExecStream wraps incoming msync events with Rsync event logic that is
// responsible for invoking rsync process and ensuring final index state.
func (r *Rsync) ExecStream(evC <-chan *msync.Event) <-chan msync.Execer {
	exC := make(chan msync.Execer)

	go func() {
		defer close(exC)
		for {
			select {
			case ev, ok := <-evC:
				if !ok {
					return
				}

				ex := &Event{
					ev:     ev,
					parent: r,
				}
				select {
				case exC <- ex:
				case <-r.stopC:
					return
				}
			case <-r.stopC:
				return
			}
		}
	}()

	return exC
}

// Close stops all created synchronization streams.
func (r *Rsync) Close() error {
	r.once.Do(func() {
		close(r.stopC)
	})

	return nil
}
