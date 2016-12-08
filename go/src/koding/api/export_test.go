package api

import (
	"fmt"
	"net/http"
	"testing"

	"github.com/koding/logging"
)

// Log is a logger for use in tests.
var Log = logging.NewCustom("api", testing.Verbose())

// WriteTo exports writeTo for test purposes.
func (s *Session) WriteTo(req *http.Request) { s.writeTo(req) }

// ReadFrom exports readFrom for test purposes.
func (s *Session) ReadFrom(req *http.Request) { s.readFrom(req) }

// HTTPTransport exports httpTransport for test purposes.
type HTTPTransport interface {
	httpTransport
}

// HTTPRequestCanceler exports httpRequestCanceler for test purposes.
type HTTPRequestCanceler interface {
	httpRequestCanceler
}

// HTTPIdleConnectionsCloser exports httpIdleConnectionsCloser for
// tests purposes.
type HTTPIdleConnectionsCloser interface {
	httpIdleConnectionsCloser
}

// Match is a test helper for matching two sessions.
//
// Since ClientID is typically auto-generated, we match all the other fields.
func (s *Session) Match(other *Session) error {
	if s.User.Username != other.User.Username {
		return fmt.Errorf("username is  %q, the other one is %q", s.User.Username, other.User.Username)
	}

	if s.User.Team != other.User.Team {
		return fmt.Errorf("team is  %q, the other one is %q", s.User.Team, other.User.Team)
	}

	return nil
}
