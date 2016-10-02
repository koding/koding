package credential

import (
	"fmt"
	"net/http"
	"net/url"
	"sync"

	"koding/db/mongodb"
	"koding/kites/kloud/utils/object"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/logging"
)

type validator interface {
	Valid() error
}

// NotFoundError represents an error fetching credentials.
//
// Identfiers of credentials that are missing in the underlying
// storage are listed in the Identifiers field.
type NotFoundError struct {
	Identifiers []string
	Err         error
}

// Error implements the built-in error interface.
func (e *NotFoundError) Error() string {
	if e.Err != nil {
		return fmt.Sprintf("%v credentials not found due to the error: %s", e.Identifiers, e.Err)
	}

	return fmt.Sprintf("%v credentials not found", e.Identifiers)
}

// Fetcher provides an interface for fetching credentials.
type Fetcher interface {
	// Fetch obtains credentials from the underlying store for the given
	// username and credential identifiers.
	//
	// The creds parameters maps identifier string to a credential
	// data value.
	//
	// If the data value is non-nil, the method will decode fetched
	// credential data from the underlying representation (e.g. bson.M
	// for MongoDB credentials store) to the given value. The behaviour
	// for the decoding can be altered by providing custom ObjectBuilder
	// via StoreOptions param. By default object.HCLBuilder decoding
	// is used. If the data value implements stack.Validator interface,
	// it will be used to ensure decoding was successful.
	//
	// If the data value is nil, the fetcher will use store-specific
	// representation. This is used to defer decoding of the data
	// value, leaving it to the caller.
	Fetch(username string, creds map[string]interface{}) error
}

// Putter provides an interface for inserting/updating credentials.
type Putter interface {
	Put(username string, creds map[string]interface{}) error
}

// Store provides reading/writing credential data values.
type Store interface {
	Fetcher
	Putter
}

// Options are used to alter default behavior of credential store
// implementations.
type Options struct {
	MongoDB       *mongodb.MongoDB
	Log           logging.Logger
	CredURL       *url.URL
	ObjectBuilder *object.Builder
	Client        *http.Client
}

func (opts *Options) objectBuilder() *object.Builder {
	if opts.ObjectBuilder != nil {
		return opts.ObjectBuilder
	}

	return object.HCLBuilder
}

func (opts *Options) new(logName string) *Options {
	optsCopy := *opts
	optsCopy.Log = opts.Log.New(logName)

	return &optsCopy
}

// NewStore gives new credential store for the given options.
//
// The returned Store keeps all credentials encrypted in Sneaker.
func NewStore(opts *Options) Store {
	if opts.CredURL == nil {
		return &mongoStore{
			Options: opts.new("mongo"),
		}
	}

	return &socialStore{
		Options: opts.new("social"),
	}
}

// MigratingStore creates a Store that on Fetch tries to fetch
// credentials from dst first and for every missing credential it
// falls back to src. Every credential fetched from src store
// is then put back to the dst one.
//
// On Put migrating store puts the credential both to src and dst
// stores.
func MigratingStore(src, dst Store) Store {
	return struct {
		Fetcher
		Putter
	}{
		Fetcher: NewFallbackFetcher(
			dst,
			&TeeFetcher{Fetcher: src, Putter: dst},
		),
		Putter: NewMultiPutter(dst, src),
	}
}

func toIdents(creds map[string]interface{}) []string {
	idents := make([]string, 0, len(creds))
	for ident := range creds {
		idents = append(idents, ident)
	}

	return idents
}

// FallbackFetcher fetches credential datas recovering from *NotFoundError
// by fetching missing ones with next fetcher until nil error is returned.
type FallbackFetcher struct {
	Fetchers []Fetcher
}

// NewFallbackFetcher gives new chained fallback fetchers for the given ones.
func NewFallbackFetcher(fetchers ...Fetcher) Fetcher {
	return &FallbackFetcher{
		Fetchers: fetchers,
	}
}

// Fetch implements the Fetcher interface than handles *NotFoundError by
// trying to fetch missing credentials from the next fetcher from
// the Fetchers slice.
func (ff *FallbackFetcher) Fetch(username string, creds map[string]interface{}) error {
	left := creds

	for _, f := range ff.Fetchers {
		if len(left) == 0 {
			break
		}

		err := f.Fetch(username, left)
		e, ok := err.(*NotFoundError)

		if err != nil && !ok {
			// errors other than *NotFoundError can't be recovered from
			return err
		}

		// ensure all fetched data values are updated in creds map
		if err == nil || ok {
			for ident, data := range left {
				// ensure the ident was requested so we do not leak
				// excessive data values
				if _, ok := creds[ident]; ok {
					creds[ident] = data
				}
			}
		}

		left = make(map[string]interface{})

		if err == nil {
			break
		}

		for _, ident := range e.Identifiers {
			data, ok := creds[ident]
			if !ok {
				// this should not happen, can't have not found error
				// for a credential that was not requested; safe to ignore
				continue
			}

			left[ident] = data
		}
	}

	if len(left) != 0 {
		return &NotFoundError{
			Identifiers: toIdents(left),
		}
	}

	return nil
}

// TeeFetcher creates/updates with Putter each credential data
// that was fetched by Fetcher.
type TeeFetcher struct {
	Fetcher Fetcher
	Putter  Putter
}

// TeeFetcher implements the Fetcher interfaces which puts each fetched
// credential data from F to P.
func (tf *TeeFetcher) Fetch(username string, creds map[string]interface{}) error {
	err := tf.Fetcher.Fetch(username, creds)
	e, ok := err.(*NotFoundError)

	if err != nil && !ok {
		// early return - no credential was fetched
		return &NotFoundError{
			Identifiers: toIdents(creds),
			Err:         err,
		}
	}

	fetched := make(map[string]interface{})

	for ident, data := range creds {
		fetched[ident] = data
	}

	// if there are missing credential datas, remove them from fetched
	if ok && e != nil {
		for _, ident := range e.Identifiers {
			delete(fetched, ident)
		}
	}

	if len(fetched) != 0 {
		// ignore errors from Put, we're going to retry putting
		// credential data next time it's fetched
		tf.Putter.Put(username, fetched)
	}

	return err
}

// MultiPutter is a putter that duplicates each Put to all the provided
// Putters, concurrently.
type MultiPutter struct {
	Putters []Putter
}

// NewMultiPutter gives new duplicating putter for the given putter values.
func NewMultiPutter(putters ...Putter) Putter {
	return &MultiPutter{
		Putters: putters,
	}
}

// Put implements the Putter interface.
func (mp *MultiPutter) Put(username string, creds map[string]interface{}) error {
	var (
		err error
		mu  sync.Mutex
		wg  sync.WaitGroup
	)

	for _, p := range mp.Putters {
		wg.Add(1)

		go func(p Putter) {
			defer wg.Done()

			if e := p.Put(username, creds); e != nil {
				mu.Lock()
				err = multierror.Append(err, e)
				mu.Unlock()
			}
		}(p)
	}

	wg.Wait()

	return err
}

type store struct {
	Fetcher
	Putter
}
