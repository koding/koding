package socialapi

import (
	"fmt"
	"net/http"
)

// WriteTo exports writeTo for test purposes.
func (s *Session) WriteTo(req *http.Request) { s.writeTo(req) }

// ReadFrom exports readFrom for test purposes.
func (s *Session) ReadFrom(req *http.Request) { s.readFrom(req) }

// HTTPTransport exports httpTransport for test purposes.
type HTTPTransport interface {
	httpTransport
}

// Match is a test helper for matching two sessions.
//
// Since ClientID is typically auto-generated, we match all the other fields.
func (s *Session) Match(other *Session) error {
	if s.Username != other.Username {
		return fmt.Errorf("username is  %q, the other one is %q", s.Username, other.Username)
	}

	if s.Team != other.Team {
		return fmt.Errorf("team is  %q, the other one is %q", s.Team, other.Team)
	}

	return nil
}
