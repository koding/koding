package collaboration

import (
	"errors"
	"strings"
	"sync"

	"github.com/koding/kite"
)

type SharedUsers struct {
	AllowedUsers map[string]bool
	mu           sync.Mutex
}

func New() *SharedUsers {
	return &SharedUsers{
		AllowedUsers: make(map[string]bool),
	}
}

func (s *SharedUsers) Share(r *kite.Request) (interface{}, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var params struct {
		Username string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
	}

	if _, ok := s.AllowedUsers[params.Username]; ok {
		return nil, errors.New("user is already in the shared list.")
	}

	s.AllowedUsers[params.Username] = true

	return "shared", nil
}

func (s *SharedUsers) Unshare(r *kite.Request) (interface{}, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	var params struct {
		Username string
	}

	if r.Args.One().Unmarshal(&params) != nil || params.Username == "" {
		return nil, errors.New("Wrong usage.")
	}

	if _, ok := s.AllowedUsers[params.Username]; !ok {
		return nil, errors.New("user is not in the shared list.")
	}

	delete(s.AllowedUsers, params.Username)

	return "unshared", nil
}

func (s *SharedUsers) Shared(r *kite.Request) (interface{}, error) {
	shared := make([]string, 0)
	for user := range s.AllowedUsers {
		shared = append(shared, user)
	}

	return strings.Join(shared, ","), nil
}
