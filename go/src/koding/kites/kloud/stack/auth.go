package stack

import (
	"errors"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"

	"github.com/koding/kite"
	uuid "github.com/satori/go.uuid"
	mgo "gopkg.in/mgo.v2"
)

// LoginRequest represents a request model for "auth.login"
// kloud's kite method.
type LoginRequest struct {
	// GroupName is a team name, which we're going to log in to.
	//
	// If empty, default team is going to be used
	// instead and its name can be read from response value.
	GroupName string `json:"groupName"`

	// Metadata whether
	Metadata bool `json:"metadata,omitempty"`
}

var _ Validator = (*LoginRequest)(nil)

func (req *LoginRequest) Valid() error {
	if req.GroupName == "" {
		req.GroupName = models.KDIOGroupName
	}
	return nil
}

// LoginResponse represents a response model for "auth.login"
// kloud's kite method.
type LoginResponse struct {
	// ClientID represents a session ID used for
	// authentication with remote.api and Social API.
	ClientID string `json:"clientID"`

	// GroupName is a team name, which we have just logged in to.
	GroupName string `json:"groupName"`

	// Username is a name of the user, which we have just logged in as.
	Username string `json:"username"`

	// Metadata represents a Koding configuration, used by client
	// to ensure valid configuration.
	//
	// The field is non-nil, if Metadata in request was true.
	Metadata *Metadata `json:"metadata,omitempty"`
}

type PasswordLoginRequest struct {
	LoginRequest

	Username string `json:"username"`
	Password string `json:"password"`
}

var _ Validator = (*PasswordLoginRequest)(nil)

func (req *PasswordLoginRequest) Valid() error {
	if req.Username == "" {
		return errors.New("invalid empty username")
	}
	if req.Password == "" {
		return errors.New("invalid empty password")
	}
	return req.LoginRequest.Valid()
}

type PasswordLoginResponse struct {
	LoginResponse

	KiteKey string `json:"kiteKey,omitempty"`
}

// AuthLogin creates a jSession for the given username and team.
//
// If a session already exists, the method is a nop and returns
// already existing one.
//
// TODO(rjeczalik): Add AuthLogout to force creation of a new
// session.
func (k *Kloud) AuthLogin(r *kite.Request) (interface{}, error) {
	k.Log.Debug("AuthLogin called by %q with %q", r.Username, r.Args.Raw)

	var req LoginRequest

	if err := getReq(r, &req); err != nil {
		return nil, err
	}

	return k.authLogin(r.Username, &req)
}

func (k *Kloud) authLogin(username string, req *LoginRequest) (*LoginResponse, error) {
	ses, err := modelhelper.UserLogin(username, req.GroupName)
	switch err {
	case nil:
	case mgo.ErrNotFound:
		return nil, NewError(ErrBadRequest)
	case modelhelper.ErrNotParticipant:
		return nil, NewError(ErrNotAuthorized)
	default:
		k.Log.Debug("Got generic error for UserLogin, username: %q, err: %q", username, err)
		return nil, NewError(ErrInternalServer)
	}

	resp := &LoginResponse{
		ClientID:  ses.ClientId,
		GroupName: req.GroupName,
		Username:  username,
	}

	if req.Metadata {
		resp.Metadata = &Metadata{
			Endpoints: k.Endpoints,
		}
	}

	return resp, nil
}

func (k *Kloud) AuthPasswordLogin(r *kite.Request) (interface{}, error) {
	var req PasswordLoginRequest

	if err := getReq(r, &req); err != nil {
		return nil, err
	}

	if _, err := modelhelper.CheckAndGetUser(req.Username, req.Password); err != nil {
		return nil, errors.New("username and/or password does not match")
	}

	resp, err := k.authLogin(req.Username, &req.LoginRequest)
	if err != nil {
		return nil, err
	}

	kiteKey, err := k.Userdata.Keycreator.Create(req.Username, uuid.NewV4().String())
	if err != nil {
		return nil, err
	}

	return &PasswordLoginResponse{
		LoginResponse: *resp,
		KiteKey:       kiteKey,
	}, nil
}

func getReq(r *kite.Request, req interface{}) error {
	if r.Args == nil {
		return NewError(ErrNoArguments)
	}

	if err := r.Args.One().Unmarshal(req); err != nil {
		return NewError(ErrBadRequest)
	}

	if v, ok := req.(Validator); ok {
		return v.Valid()
	}

	return nil
}
