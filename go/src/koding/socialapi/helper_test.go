package socialapi_test

import (
	"fmt"

	"koding/kites/kloud/utils"
	"koding/socialapi"
)

type FakeAuth map[string]*socialapi.Session

func (fa FakeAuth) Auth(opts *socialapi.AuthOptions) (*socialapi.Session, error) {
	session, ok := fa[opts.Session.Key()]
	if !ok || opts.Refresh {
		session = &socialapi.Session{
			ClientID: utils.RandString(12),
			Username: opts.Session.Username,
			Team:     opts.Session.Team,
		}
		fa[opts.Session.Key()] = session
	}

	return session, nil
}

type Trx struct {
	Type    string // "set", "get" or "delete"
	Session *socialapi.Session
}

type TrxStorage []Trx

var _ socialapi.Storage = (*TrxStorage)(nil)

func (trx *TrxStorage) Get(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "get", Session: s})

	trxS, ok := trx.Build()[s.Key()]
	if !ok {
		return socialapi.ErrSessionNotFound
	}

	*s = *trxS

	return nil
}

func (trx *TrxStorage) Set(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "set", Session: s})
	return nil
}

func (trx *TrxStorage) Delete(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "delete", Session: s})
	return nil
}

func (trx TrxStorage) Match(other TrxStorage) error {
	if len(trx) != len(other) {
		return fmt.Errorf("current storage has %d trxs, the other has %d", len(trx), len(other))
	}

	for i, trx := range trx {
		if trx.Type != other[i].Type {
			return fmt.Errorf("trx %d is of %q type, the other one is %q",
				i, trx.Type, other[i].Type)
		}

		if trx.Session.Username != other[i].Session.Username {
			return fmt.Errorf("trx %d username is  %q, the other one is %q",
				i, trx.Session.Username, other[i].Session.Username)
		}

		if trx.Session.Team != other[i].Session.Team {
			return fmt.Errorf("trx %d team is  %q, the other one is %q",
				i, trx.Session.Team, other[i].Session.Team)
		}
	}

	return nil
}

func (trx TrxStorage) Build() map[string]*socialapi.Session {
	m := make(map[string]*socialapi.Session)

	for _, trx := range trx {
		switch trx.Type {
		case "get":
			// read-only op, ignore
		case "set":
			m[trx.Session.Key()] = trx.Session
		case "delete":
			delete(m, trx.Session.Key())
		}
	}

	return m
}
