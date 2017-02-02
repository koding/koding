package collaboration

import (
	"errors"
	"strings"

	"github.com/boltdb/bolt"
	"github.com/koding/kite"
)

type Collaboration struct {
	Storage
}

func New(boltDB *bolt.DB) *Collaboration {
	var db Storage
	var err error

	// Try the persistent storage first. If it fails, try the in-memory one.
	db, err = NewBoltStorage(boltDB)
	if err != nil {
		db = NewMemoryStorage()
	}

	return &Collaboration{
		Storage: db,
	}
}

func (c *Collaboration) Share(r *kite.Request) (interface{}, error) {
	var params struct {
		Username  string
		Permanent bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
	}

	option, err := c.Get(params.Username)
	if err == nil {
		// if the user is already a permanent user just return lazily, we don't
		// need change anything
		if option.Permanent {
			return "shared", nil
		}
	}

	newOption := &Option{Permanent: params.Permanent}
	if err := c.Set(params.Username, newOption); err != nil {
		return nil, errors.New("user is already in the shared list.")
	}

	return "shared", nil
}

func (c *Collaboration) Unshare(r *kite.Request) (interface{}, error) {
	var params struct {
		Username  string
		Permanent bool
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
	}

	// if permanent is not true, check if the user has the permanent flag,
	// because we don't touch them
	if !params.Permanent {
		option, err := c.Get(params.Username)
		if err != nil {
			return nil, err
		}

		if option.Permanent {
			return nil, errors.New("user is permanent")
		}
	}

	if err := c.Delete(params.Username); err != nil {
		return nil, errors.New("user is not in the shared list.")
	}

	return "unshared", nil
}

func (c *Collaboration) Shared(r *kite.Request) (interface{}, error) {
	users, err := c.GetAll()
	if err != nil {
		return nil, err
	}

	usernames := make([]string, 0)
	for username := range users {
		usernames = append(usernames, username)
	}

	return strings.Join(usernames, ","), nil
}
