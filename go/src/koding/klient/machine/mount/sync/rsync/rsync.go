package rsync

import (
	"bytes"
	"sync"
	"sync/atomic"
	"time"

	"koding/kites/config"
	"koding/klient/machine/client"
	msync "koding/klient/machine/mount/sync"
	"koding/klient/machine/transport/rsync"
	"koding/klientctl/ssh"
)

// Builder is a factory for rsync-based synchronization objects.
type Builder struct{}

// Build satisfies msync.Builder interface. It produces Rsync objects from a
// given options if rsync executable is present in $PATH.
func (Builder) Build(opts *msync.BuildOpts) (msync.Syncer, error) {
	return NewRsync(opts)
}

// Event is a rsync synchronization object that utilizes rsync executable.
type Event struct {
	ev     *msync.Event
	parent *Rsync

	done   uint64
	output bytes.Buffer
}

// Event returns base event which is going to be synchronized.
func (e *Event) Event() *msync.Event {
	return e.ev
}

// Exec satisfies msync.Execer interface. It executes rsync executable with
// arguments available to sync stored change.
func (e *Event) Exec() error {
	defer e.ev.Done()
	if !e.ev.Valid() {
		return nil
	}

	host, port, err := e.parent.dynSSH()
	if err != nil {
		return err
	}

	var change = e.ev.Change()

	err = (&rsync.Command{
		SourcePath:      e.parent.local,
		DestinationPath: e.parent.remote,
		Username:        e.parent.username,
		PrivateKeyPath:  e.parent.privKeyPath,
		Host:            host,
		SSHPort:         port,
		Change:          change,
		Output:          &e.output,
	}).Run(e.ev.Context())

	atomic.StoreUint64(&e.done, 1)

	if err != nil {
		return err
	}

	e.parent.indexSync(change)

	return nil
}

// String implements fmt.Stringer interface. It pretty prints internal event.
func (e *Event) String() string {
	return e.ev.String() + " - " + "rsync"
}

// Debug stores the output of rsync command. This function is useful when one
// wants to see underlying behavior and/or potential errors after executing the
// event.
func (e *Event) Debug() string {
	// Do not check buffer until rsync comand exits. This prevents data races.
	if isDone := atomic.LoadUint64(&e.done); isDone == 0 {
		return "(output is not available yet)"
	}

	return e.output.String()
}

// Rsync uses rsync(1) file-copying tool to provide synchronization between
// remote and local files.
type Rsync struct {
	remote      string // remote directory root.
	local       string // local directory root.
	privKeyPath string // ssh private key path.
	username    string // remote username.

	dynSSH    msync.DynamicSSHFunc // address of connected machine.
	indexSync msync.IndexSyncFunc  // callback used to update index.

	once  sync.Once
	stopC chan struct{} // channel used to close any opened exec streams.
}

// NewRsync creates a new Rsync object from given options.
func NewRsync(opts *msync.BuildOpts) (*Rsync, error) {
	// Get path for SSH private key.
	privKeyPath, err := userSSHPrivateKeyPath()
	if err != nil {
		return nil, err
	}

	// Get remote machine user name.
	username, err := client.NewSupervised(opts.ClientFunc, 10*time.Second).CurrentUser()
	if err != nil {
		return nil, err
	}

	return &Rsync{
		remote:      opts.RemoteDir,
		local:       opts.CacheDir,
		privKeyPath: privKeyPath,
		username:    username,
		dynSSH:      opts.SSHFunc,
		indexSync:   opts.IndexSyncFunc,
		stopC:       make(chan struct{}),
	}, nil
}

// userSSHPrivateKeyPath gets the filepath to user's private SSH key.
func userSSHPrivateKeyPath() (string, error) {
	path, err := ssh.GetKeyPath(config.CurrentUser.User)
	if err != nil {
		return "", err
	}

	_, privKeyPath, err := ssh.KeyPaths(path)
	if err != nil {
		return "", err
	}

	return privKeyPath, nil
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
					ex.ev.Done()
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
