package credential

import (
	"errors"

	"gopkg.in/mgo.v2/bson"
)

// Cred represents a single stack credential.
type Cred struct {
	Ident    string      `json:"ident"`          // unique identifier
	Provider string      `json:"provider"`       // stack provider
	Title    string      `json:"title"`          // user-provided title
	Team     string      `json:"team,omitempty"` // team name
	Perm     Perm        `json:"-"`              // permission access, non-nil if validated
	Data     interface{} `json:"data,omitempty"` // the actual credential kept in a safe store
}

// Valid implements the stack.Validator interface.
func (c *Cred) Valid() error {
	if c.Perm == nil {
		return errors.New("cred: missing access permission")
	}
	if _, ok := c.Perm.(*Filter); ok {
		return errors.New("cred: not validated")
	}
	return nil
}

// Filter is used for filtering credential records.
//
// It implements Perm interface - when a *Filter value
// is assigned to a Cred.Perm field, it means we
// request Database to validate the credential
// against the given fields.
//
// E.g. setting the following Cred.Perm means
// we want to ensure the credential is valid,
// by checking whether it belongs to the user John
// and Work team.
//
//   cred := &Cred{
//       Ident: "57fbae90b89663679ef72e1a",
//       Perm:  &Filter{
//           User: "John",
//           Team: "Work",
//       },
//   }
type Filter struct {
	Ident     string   // unique identifier
	Provider  string   // stack provider
	Teamname  string   // team name
	Username  string   // user name
	RoleNames []string // roles the user has within team
}

var _ Perm = (*Filter)(nil)

// User implements the Perm interface.
func (f *Filter) User() string    { return f.Username }
func (f *Filter) Team() string    { return f.Teamname }
func (f *Filter) Roles() []string { return f.RoleNames }

func (f *Filter) Valid() error {
	if f.Username == "" {
		return errors.New("filter: invalid empty user")
	}
	return nil
}

// Perm represents an access permission for a validated
// credential - it describes who, within what team and
// with which roles can use the credential, to which
// it's attached.
type Perm interface {
	User() string
	Team() string
	Roles() []string
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

// Client allowes for CRUD on user credentials, thus Client for credentials.
type Client struct {
	db    Database
	store Store
}

// NewClient gives new Client for the given credentials.
func NewClient(opts *Options) *Client {
	return &Client{
		db: &mongoDatabase{
			Options: opts.new("database"),
		},
		store: NewStore(opts),
	}
}

// Creds returns all credentials that match the filter.
func (c *Client) Creds(filter *Filter) ([]*Cred, error) {
	return c.db.Creds(filter)
}

// SetCred edits or creates credential from the given cred value
// and for the given user.
//
// If cred.Ident is non-empty, the credential is expected to already
// exist and belong to the given user with an owner role.
func (c *Client) SetCred(username string, cred *Cred) error {
	credCopy := *cred

	if credCopy.Perm == nil {
		credCopy.Perm = &Filter{
			Username: username,
			Teamname: cred.Team,
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
