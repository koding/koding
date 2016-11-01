package credential

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"path"

	"koding/db/mongodb/modelhelper"

	"github.com/hashicorp/go-multierror"
	"gopkg.in/mgo.v2"
)

// socialStore implements fetching/updating credential data values
// from socialapi/credential endpoint.
type socialStore struct {
	*Options
}

var _ Store = (*socialStore)(nil)

type socialRequest struct {
	method   string
	clientID string
	ident    string
	body     interface{}
	resp     interface{}
}

type socialError struct {
	StatusCode  int    `json:"status,omitempty"`
	Description string `json:"description,omitempty"`
	Code        string `json:"error,omitempty"`
}

func (err *socialError) Error() string {
	return fmt.Sprintf("%s (status=%d, error=%q)", err.Description, err.StatusCode, err.Code)
}

func (s *socialStore) Fetch(username string, creds map[string]interface{}) error {
	clientID, err := s.clientID(username)
	if err != nil {
		return &NotFoundError{
			Identifiers: toIdents(creds),
			Err:         err,
		}
	}

	var missing []string
	for ident, data := range creds {
		req := &socialRequest{
			method:   "GET",
			clientID: clientID,
			ident:    ident,
			resp:     data,
		}

		if err := s.do(req); err != nil {
			s.Log.Debug("failed to fetch credential data for %q: %s", ident, err)

			missing = append(missing, ident)
			continue
		}

		if data == nil {
			creds[ident] = req.resp
		}

		s.Log.Debug("fetched credential data for %q: %v", ident, creds[ident])
	}

	if len(missing) != 0 {
		return &NotFoundError{
			Identifiers: missing,
		}
	}

	return nil
}

func (s *socialStore) Put(username string, creds map[string]interface{}) error {
	clientID, err := s.clientID(username)
	if err != nil {
		return err
	}

	for ident, data := range creds {
		req := &socialRequest{
			method:   "POST",
			clientID: clientID,
			ident:    ident,
			body:     data,
		}

		if e := s.do(req); e != nil {
			s.Log.Debug("failed to put credential data for %q: %s", ident, e)

			err = multierror.Append(err, e)
			continue
		}

		s.Log.Debug("put credential data for %q: %+v", ident, data)
	}

	return err
}

func (s *socialStore) clientID(username string) (string, error) {
	if username == "" {
		return "", errors.New("social store: empty username")
	}

	sessions, err := modelhelper.GetSessionsByUsername(username)

	for _, session := range sessions {
		if session.ClientId != "" {
			return session.ClientId, nil
		}
	}

	if err == nil {
		err = mgo.ErrNotFound
	}

	return "", fmt.Errorf("social store: unable to obtain session for %q: %s", username, err)
}

func (s *socialStore) do(req *socialRequest) error {
	u := *s.CredURL
	u.Path = path.Join(u.Path, req.ident)

	var body io.Reader
	if req.body != nil {
		if validator, ok := req.body.(validator); ok {
			if err := validator.Valid(); err != nil {
				return fmt.Errorf("%q: failed valitating data: %s", req.ident, err)
			}
		}

		p, err := json.Marshal(req.body)
		if err != nil {
			return fmt.Errorf("%q: unable to encode: %s", req.ident, err)
		}
		body = bytes.NewReader(p)
	}

	r, err := http.NewRequest(req.method, u.String(), body)
	if err != nil {
		return fmt.Errorf("%q: unable to create request: %s", req.ident, err)
	}

	if body != nil {
		r.Header.Add("Content-Type", "application/json")
	}

	r.AddCookie(&http.Cookie{
		Name:  "clientId",
		Value: req.clientID,
	})

	resp, err := s.Client.Do(r)
	if err != nil {
		return fmt.Errorf("%q: calling social api failed: %s", req.ident, err)
	}
	defer resp.Body.Close()

	if e := socialCheckError(resp); e != nil {
		return fmt.Errorf("%q: calling social api failed: %s", req.ident, e)
	}

	if req.resp != nil {
		err := json.NewDecoder(resp.Body).Decode(req.resp)
		if err != nil {
			return fmt.Errorf("%q: failed decoding data: %s", req.ident, err)
		}

		if validator, ok := req.resp.(validator); ok {
			if err := validator.Valid(); err != nil {
				return fmt.Errorf("%q: failed valitating data: %s", req.ident, err)
			}
		}
	} else {
		p, err := ioutil.ReadAll(resp.Body)
		if err == nil && len(p) != 0 {
			req.resp = p
		}
	}

	return nil
}

func socialCheckError(resp *http.Response) *socialError {
	switch resp.StatusCode {
	case http.StatusOK, http.StatusNoContent:
		return nil
	}

	err := &socialError{
		StatusCode:  resp.StatusCode,
		Description: http.StatusText(resp.StatusCode),
		Code:        resp.Status,
	}

	// ignore decoding errors, if body is empty/broken,
	// we're going to use default error value
	json.NewDecoder(resp.Body).Decode(err)

	return err
}
