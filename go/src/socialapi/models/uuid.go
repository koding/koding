package models

import (
	"encoding/hex"
	"encoding/json"
	"strings"
	"time"

	"github.com/streadway/simpleuuid"
)

const (
	size = 16
)

type Token simpleuuid.UUID

func (t Token) String() string {
	// in any case, add defansive check
	if len(t) < size {
		return ""
	}

	return hex.EncodeToString(t[0:4]) + "-" +
		hex.EncodeToString(t[4:6]) + "-" +
		hex.EncodeToString(t[6:8]) + "-" +
		hex.EncodeToString(t[8:10]) + "-" +
		hex.EncodeToString(t[10:16])
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (t *Token) UnmarshalJSON(b []byte) error {
	var field string
	if err := json.Unmarshal(b, &field); err != nil {
		return err
	}

	uuid, err := simpleuuid.NewString(field)
	if err != nil {
		return err
	}

	*t = Token(uuid)

	return nil
}

// MarshalJSON implements the json.Marshaler interface.
func (t Token) MarshalJSON() ([]byte, error) {
	return []byte(`"` + t.String() + `"`), nil
}

func NewToken(t time.Time) Token {
	token, err := simpleuuid.NewTime(t)
	if err == nil {
		return Token(token)
	}

	// try again
	token, err = simpleuuid.NewTime(t)
	if err == nil {
		return Token(token)
	}

	panic(err)
}

// Parse and allocate from a string encoded UUID like:
// "6ba7b811-9dad-11d1-80b4-00c04fd430c8".  Does not validate the time, node
// or clock are reasonable values, though it is intended to round trip from a
// string to a string for all versions of UUIDs.
func NewTokenString(s string) Token {
	normalized := strings.Replace(s, "-", "", -1)

	if hex.DecodedLen(len(normalized)) != size {
		return Token([]byte{})
	}

	bytes, err := hex.DecodeString(normalized)
	if err != nil {
		return Token([]byte{})
	}

	return Token(bytes)
}
