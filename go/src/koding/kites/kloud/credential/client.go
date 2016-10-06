package credential

import (
	"errors"

	"gopkg.in/mgo.v2/bson"
)

type Cred struct {
	Ident    string      `json:"ident"`
	Provider string      `json:"provider"`
	Title    string      `json:"title"`
	Team     string      `json:"team,omitempty"`
	Perm     Perm        `json:"-"`
	Data     interface{} `json:"data,omitempty"`
}

func (c *Cred) Valid() error {
	if c.Perm == nil {
		return errors.New("cred: missing access permission")
	}
	if _, ok := c.Perm.(*Filter); ok {
		return errors.New("cred: not validated")
	}
	return nil
}

type Filter struct {
	Ident    string
	Provider string
	Team     string
	User     string
	Roles    []string
}

func (f *Filter) PermUser() string    { return f.User }
func (f *Filter) PermTeam() string    { return f.Team }
func (f *Filter) PermRoles() []string { return f.Roles }

func (f *Filter) Valid() error {
	if f.User == "" {
		return errors.New("filter: invalid empty user")
	}
	return nil
}

type Perm interface {
	PermUser() string
	PermTeam() string
	PermRoles() []string
}

var (
	DefaultRoles = UserRole

	UserRole  = []string{"owner", "user"}
	OwnerRole = []string{"owner"}
)

// Database abstracts database read/write access to the credentials.
//
// The default MongoDB implementation provides access to jCredentials
// collection.
//
// TODO(rjeczalik): Add support for context.Context (caching, timeouts).
type Database interface {
	// Validate validates credential, whether f.User is allowed to have
	// all of the f.Roles within f.Team for the given credential.
	//
	// If f.Roles are empty, DefaultRoles are used instead.
	//
	// If f.Team is empty, only private access is tested.
	//
	// If credential.Perm is nil, it is set to the returned value on success.
	//
	// If credential.Perm is validated already and it matches the given filter,
	// the function should be a nop and the credential.Perm returned.
	//
	// If credential.Perm is of *Filter type, it is going to be ignored and
	// superseded by filter.
	Validate(filter *Filter, credential *Cred) (Perm, error)

	// Creds returns all the validated credentials it can find for
	// the given filter.
	//
	// It should return only credential metadata, without the actual
	// content (unset Data field).
	Creds(filter *Filter) ([]*Cred, error)

	// SetCred creates or updates the given credential.
	//
	// If the credential.Perm is of *Filter type, the validation data
	// is going to be created / updated.
	//
	// Otherwise the given credential is expected to be already validated.
	SetCred(credential *Cred) error

	// Lock locks the given credential.
	Lock(*Cred) error

	// Unlock unlocks the given credential.
	Unlock(*Cred) error
}

type Client struct {
	db    Database
	store Store
}

func NewClient(opts *Options) *Client {
	return &Client{
		db: &mongoDatabase{
			Options: opts.new("database"),
		},
		store: NewStore(opts),
	}
}

func (c *Client) Creds(f *Filter) ([]*Cred, error) {
	return c.db.Creds(f)
}

func (c *Client) SetCred(username string, cred *Cred) error {
	credCopy := *cred

	if credCopy.Perm == nil {
		credCopy.Perm = &Filter{
			User: username,
			Team: cred.Team,
		}
	}

	if credCopy.Ident == "" {
		credCopy.Ident = bson.NewObjectId().Hex()
	}

	if err := c.db.SetCred(&credCopy); err != nil {
		return err
	}

	if cred.Ident == "" {
		cred.Ident = credCopy.Ident
	}

	if cred.Title == "" {
		cred.Title = credCopy.Title
	}

	if credCopy.Data == nil {
		credCopy.Data = make(map[string]interface{})
	}

	data := map[string]interface{}{
		credCopy.Ident: credCopy.Data,
	}

	return c.store.Put(username, data)
}

func (c *Client) Lock(cred *Cred) error {
	return c.db.Lock(cred)
}

func (c *Client) Unlock(cred *Cred) error {
	return c.db.Unlock(cred)
}
