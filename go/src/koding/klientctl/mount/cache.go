// Various types and functions used by `kd mount`.
//
// TODO: Move klientctl/mount.go to this package.
package mount

import (
	"errors"
	"fmt"
	"io"

	"github.com/koding/kite/dnode"

	"github.com/cheggaaa/pb"
	"github.com/koding/kite"
	"github.com/koding/logging"
)

// CacheCallbackInit contains various fields required for a Command instance to
// be initialized.
type CacheCallbackInit struct {
	Stdout io.Writer
	Log    logging.Logger
}

// CacheCallback implements cli UX for a remote.cache method progress callback.
//
// It does **not** implement any type of concurrent callback support, do not use
// a CacheCallback multiple times at the same time.
type CacheCallback struct {
	Stdout io.Writer
	Log    logging.Logger

	// The progress bar that CacheCallback will use
	Bar *pb.ProgressBar

	// doneErr is used to wait until the cache progress is done, and also send
	// any error encountered. We simply send nil if there is no error.
	doneErr chan error
}

func NewCacheCallback(i CacheCallbackInit) (*CacheCallback, error) {
	if err := i.CheckValid(); err != nil {
		return nil, err
	}

	// Set the bar defaults, and visibly show the bar.
	bar := pb.New(100)
	bar.SetMaxWidth(100)
	bar.Start()

	return &CacheCallback{
		Stdout:  i.Stdout,
		Log:     i.Log,
		Bar:     bar,
		doneErr: make(chan error),
	}, nil
}

func (i CacheCallbackInit) CheckValid() error {
	if i.Stdout == nil {
		return errors.New("MissingArgument: Stdout")
	}

	if i.Log == nil {
		return errors.New("MissingArgument: Log")
	}

	return nil
}

func (cb *CacheCallback) WaitUntilDone() error {
	defer cb.Bar.Finish()

	if err := <-cb.doneErr; err != nil {
		fmt.Fprintln(cb.Stdout, "") // newline to ensure the progress bar ends
		return err
	}

	return nil
}

// Callback is the callback, used to update the progress bar as remote.cache
// downloads
func (cb *CacheCallback) Callback(par *dnode.Partial) {
	type Progress struct {
		Progress int        `json:progress`
		Error    kite.Error `json:error`
	}

	// TODO: Why is this an array from Klient? How can this be written cleaner?
	ps := []Progress{{}}
	par.MustUnmarshal(&ps)
	p := ps[0]

	cb.Log.Debug("CacheCallback Progress: %#v", p)

	if p.Error.Message != "" {
		cb.doneErr <- p.Error
	}

	cb.Bar.Set(p.Progress)

	// TODO: Disable the callback here, so that it's impossible to double call
	// the progress after competition - to avoid weird/bad UX and errors.
	if p.Progress == 100 {
		cb.doneErr <- nil
	}
}
