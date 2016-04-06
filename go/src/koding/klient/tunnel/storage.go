package tunnel

import (
	"koding/kites/tunnelproxy"
	"koding/klient/storage"

	"github.com/boltdb/bolt"
)

var (
	// dbBucket is the bucket name used to retrieve and store the resolved
	// address
	dbBucket = []byte("klienttunnel")
)

type Storage struct {
	db *storage.EncodingStorage
}

func NewStorage(db *bolt.DB) *Storage {
	return &Storage{
		db: storage.NewEncodingStorage(db, dbBucket),
	}
}

func (s *Storage) Options() (*Options, error) {
	var opts Options
	if err := s.db.GetValue("options", &opts); err != nil {
		return nil, err
	}

	return &opts, nil
}

func (s *Storage) SetOptions(opts *Options) error {
	return s.db.SetValue("options", opts)
}

func (s *Storage) Services() (tunnelproxy.Services, error) {
	srvc := make(tunnelproxy.Services)
	if err := s.db.GetValue("services", &srvc); err != nil {
		return nil, err
	}

	return srvc, nil
}

func (s *Storage) SetServices(srvc tunnelproxy.Services) error {
	return s.db.SetValue("services", srvc)
}
