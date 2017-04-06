package synctest

import (
	"context"
	"fmt"
	"time"

	"koding/klient/machine/index"
	"koding/klient/machine/index/indextest"
	msync "koding/klient/machine/mount/sync"
)

// SyncLocal sends all index changes between local and remote directories to
// provided syncer. Then it calls produced Execers. Returned contex will be
// closed when all changes are consumed and their events executed. The direction
// of changes is marked by dir argument and it must be ChangeMetaRemote and/or
// ChangeMetaRemote.
func SyncLocal(s msync.Syncer, rootA, rootB string, dir index.ChangeMeta) (context.Context, context.CancelFunc, error) {
	if dir&^(index.ChangeMetaLocal|index.ChangeMetaRemote) != 0 {
		return nil, nil, fmt.Errorf("invalid change type: %v", dir)
	}

	cs, err := indextest.Compare(rootA, rootB)
	if err != nil {
		return nil, nil, err
	}

	evs := make([]*msync.Event, 0, len(cs))
	for _, c := range cs {
		c = index.NewChange(c.Path(), c.Priority(), c.Meta()|dir)
		evs = append(evs, msync.NewEvent(context.Background(), nil, c))
	}

	var (
		evC = make(chan *msync.Event)
		exC = s.ExecStream(evC)
	)

	ctx, cancel := context.WithCancel(context.Background())
	go func() {
		defer cancel()
		for i := 0; i < len(evs); {
			select {
			case evC <- evs[i]:
			case ex := <-exC:
				ex.Exec()
				i++
			case <-ctx.Done():
				return
			}
		}
	}()

	return ctx, cancel, nil
}

// ExecChange uses provided to create Execer from provided index change. Then
// the function will execute it end return its error or timeout if such occurs.
func ExecChange(s msync.Syncer, change *index.Change, timeout time.Duration) error {
	var (
		ev  = msync.NewEvent(context.Background(), nil, change)
		evC = make(chan *msync.Event)
	)

	go func() {
		select {
		case evC <- ev:
		case <-time.After(timeout):
		}
	}()

	select {
	case ex := <-s.ExecStream(evC):
		if ex == nil {
			return fmt.Errorf("nil execer received")
		}
		return ex.Exec()
	case <-time.After(timeout):
		return fmt.Errorf("timed out after %s", timeout)
	}
}
