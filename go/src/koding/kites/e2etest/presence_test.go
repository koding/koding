package e2etest

import (
	"math/rand"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/hashicorp/go-multierror"
)

func TestE2E_Presence(t *testing.T) {
	var (
		err error
		mu  sync.Mutex // protects err
		wg  sync.WaitGroup
	)

	K := make([]*UniqueKite, 7)
	restoreK := make([]*UniqueKite, len(K))

	for i := range K {
		hostname := "kite" + strconv.Itoa(i)

		K[i] = &UniqueKite{Hostname: hostname}
		restoreK[i] = &UniqueKite{Hostname: hostname}
	}

	// Register all the unique kites.
	for i, k := range K {
		wg.Add(1)
		go func(i int, k *UniqueKite) {
			defer wg.Done()

			time.Sleep(time.Duration(3+i*(rand.Intn(3)+1)) * time.Second)

			if e := k.Register(); e != nil {
				mu.Lock()
				err = multierror.Append(err, e)
				mu.Unlock()
			}
		}(i, k)
	}

	wg.Wait()

	if err != nil {
		t.Fatal(err)
	}

	names := make(map[string]string, len(K))

	// Ensure every kite has a unique name.
	for i, kite := range K {
		name := kite.RegisteredName()

		if name == "" {
			t.Errorf("%d: empty registerURL for %q", i, kite.Hostname)
			continue
		}

		if _, ok := names[name]; ok {
			t.Errorf("%d: duplicate name for %q: %s", i, kite.Hostname, name)
			continue
		}

		names[name] = kite.RegisteredURL.String()
	}

	// Register again all the unique kites, ensure they have restored
	// their registerURLs.

	for _, k := range restoreK {
		wg.Add(1)
		go func(k *UniqueKite) {
			defer wg.Done()

			if e := k.Register(); e != nil {
				mu.Lock()
				err = multierror.Append(err, e)
				mu.Unlock()
			}
		}(k)
	}

	wg.Wait()

	if err != nil {
		t.Fatal(err)
	}

	for i := range K {
		name := K[i].RegisteredName()
		restoredName := restoreK[i].RegisteredName()

		if name != restoredName {
			t.Errorf("%d: name=%q != restoredName=%q", i, name, restoredName)
		}
	}

	t.Logf("registered names: %v", names)
}
