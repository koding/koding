package collaboration

import (
	"errors"
	"strings"

	"github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
)

type Collaboration struct {
	Storage
}

func New() *Collaboration {
	var db Storage
	var err error

	// Try the persistent storage first. If it fails, try the in-memory one.
	db, err = NewBoltStorage()
	if err != nil {
		db = NewMemoryStorage()
	}

	return &Collaboration{
		Storage: db,
	}
}

func (c *Collaboration) Share(r *kite.Request) (interface{}, error) {
	var params struct {
		Username string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
	}

	if err := c.Set(params.Username, ""); err != nil {
		return nil, errors.New("user is already in the shared list.")
	}

	return "shared", nil
}

func (c *Collaboration) Unshare(r *kite.Request) (interface{}, error) {
	var params struct {
		Username string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
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
	return strings.Join(users, ","), nil
}
