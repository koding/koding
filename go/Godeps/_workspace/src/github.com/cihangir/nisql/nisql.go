// Package nisql provides nullable types for database operations with proper
// json marshalling and unmarshalling
package nisql

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"time"

	"github.com/lib/pq"
)

var nullString = []byte("null")

//
// String
//

// String creates a valid NullString
func String(s string) NullString {
	return NullString{
		sql.NullString{
			String: s,
			Valid:  true,
		},
	}
}

// NullString is a type that can be null or a string
type NullString struct {
	sql.NullString
}

// MarshalJSON implements the json.Marshaler interface.
func (n *NullString) MarshalJSON() ([]byte, error) {
	if !n.Valid {
		return nullString, nil
	}

	return json.Marshal(n.String)
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (n *NullString) UnmarshalJSON(b []byte) error {
	return unmarshal(n, b)
}

// Get returns nil or underlying string value
func (n *NullString) Get() *string {
	if !n.Valid {
		return nil
	}

	return &n.String
}

//
// Float64
//

// Float64 creates a valid NullFloat64
func Float64(f float64) NullFloat64 {
	return NullFloat64{
		sql.NullFloat64{
			Float64: f,
			Valid:   true,
		},
	}
}

// NullFloat64 is a type that can be null or a float64
type NullFloat64 struct {
	sql.NullFloat64
}

// MarshalJSON implements the json.Marshaler interface.
func (n *NullFloat64) MarshalJSON() ([]byte, error) {
	if !n.Valid {
		return nullString, nil
	}

	return json.Marshal(n.Float64)
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (n *NullFloat64) UnmarshalJSON(b []byte) error {
	return unmarshal(n, b)
}

// Get returns nil or underlying float64 value
func (n *NullFloat64) Get() *float64 {
	if !n.Valid {
		return nil
	}

	return &n.Float64
}

//
// Int64
//

// Int64 creates a valid NullInt64
func Int64(i int64) NullInt64 {
	return NullInt64{
		sql.NullInt64{
			Int64: i,
			Valid: true,
		},
	}
}

// NullInt64 is a type that can be null or an int
type NullInt64 struct {
	sql.NullInt64
}

// MarshalJSON implements the json.Marshaler interface.
func (n *NullInt64) MarshalJSON() ([]byte, error) {
	if !n.Valid {
		return nullString, nil
	}

	return json.Marshal(n.Int64)
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (n *NullInt64) UnmarshalJSON(b []byte) error {
	return unmarshal(n, b)
}

// Get returns nil or underlying int64 value
func (n *NullInt64) Get() *int64 {
	if !n.Valid {
		return nil
	}

	return &n.Int64
}

//
// Bool
//

// Bool creates a valid NullBool
func Bool(b bool) NullBool {
	return NullBool{
		sql.NullBool{
			Bool:  b,
			Valid: true,
		},
	}
}

// NullBool is a type that can be null or a bool
type NullBool struct {
	sql.NullBool
}

// MarshalJSON implements the json.Marshaler interface.
func (n *NullBool) MarshalJSON() ([]byte, error) {
	if !n.Valid {
		return nullString, nil
	}

	return json.Marshal(n.Bool)
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (n *NullBool) UnmarshalJSON(b []byte) error {
	return unmarshal(n, b)
}

// Get returns nil or underlying bool value
func (n *NullBool) Get() *bool {
	if !n.Valid {
		return nil
	}

	return &n.Bool
}

// Time creates a valid NullTime
func Time(t time.Time) NullTime {
	return NullTime{
		pq.NullTime{
			Time:  t,
			Valid: true,
		},
	}
}

//
// time.Time
//

// NullTime is a type that can be null or a time.Time
type NullTime struct {
	pq.NullTime
}

// MarshalJSON implements the json.Marshaler interface.
func (n *NullTime) MarshalJSON() ([]byte, error) {
	if !n.Valid {
		return nullString, nil
	}

	return json.Marshal(n.Time)
}

// UnmarshalJSON implements the json.Unmarshaler interface.
func (n *NullTime) UnmarshalJSON(b []byte) error {
	if bytes.Equal(b, nullString) {
		return n.Scan(nil)
	}

	var t time.Time
	if err := json.Unmarshal(b, &t); err != nil {
		return err
	}

	return n.Scan(t)
}

// Get returns nil or underlying time.Time value
func (n *NullTime) Get() *time.Time {
	if !n.Valid {
		return nil
	}

	return &n.Time
}

func unmarshal(s sql.Scanner, b []byte) error {
	var d interface{}
	if err := json.Unmarshal(b, &d); err != nil {
		return err
	}

	return s.Scan(d)
}
