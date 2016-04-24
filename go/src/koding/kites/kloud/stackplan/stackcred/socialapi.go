package stackcred

import "errors"

// socialStore implements fetching/updating credential data values
// from socialapi/credential endpoint.
type socialStore struct {
	*StoreOptions
}

var (
	_ Fetcher = (*socialStore)(nil)
	_ Putter  = (*socialStore)(nil)
)

func (s *socialStore) Fetch(username string, creds map[string]interface{}) error {
	return &NotFoundError{
		Identifiers: toIdents(creds),
		Err:         errors.New("social fetch not implemented"),
	}
}

func (s *socialStore) Put(username string, creds map[string]interface{}) error {
	return errors.New("social put not implemented")
}
