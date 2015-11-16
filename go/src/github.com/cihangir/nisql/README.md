[![Build Status](https://travis-ci.org/cihangir/nisql.svg?branch=master)](https://travis-ci.org/cihangir/nisql)
[![GoDoc](https://godoc.org/github.com/cihangir/nisql?status.svg)](https://godoc.org/github.com/cihangir/nisql)

# nisql

```bash
go get -u github.com/cihangir/nisql
```

Package nisql provides nullable types for database operations with proper json
marshalling and unmarshalling

## Usage

#### type NullBool

```go
type NullBool struct {
    sql.NullBool
}
```

NullBool is a type that can be null or a bool

#### func  Bool

```go
func Bool(b bool) NullBool
```
Bool creates a valid NullBool

#### func (*NullBool) Get

```go
func (n *NullBool) Get() *bool
```
Get returns nil or underlying bool value

#### func (*NullBool) MarshalJSON

```go
func (n *NullBool) MarshalJSON() ([]byte, error)
```
MarshalJSON implements the json.Marshaler interface.

#### func (*NullBool) UnmarshalJSON

```go
func (n *NullBool) UnmarshalJSON(b []byte) error
```
UnmarshalJSON implements the json.Unmarshaler interface.

#### type NullFloat64

```go
type NullFloat64 struct {
    sql.NullFloat64
}
```

NullFloat64 is a type that can be null or a float64

#### func  Float64

```go
func Float64(f float64) NullFloat64
```
Float64 creates a valid NullFloat64

#### func (*NullFloat64) Get

```go
func (n *NullFloat64) Get() *float64
```
Get returns nil or underlying float64 value

#### func (*NullFloat64) MarshalJSON

```go
func (n *NullFloat64) MarshalJSON() ([]byte, error)
```
MarshalJSON implements the json.Marshaler interface.

#### func (*NullFloat64) UnmarshalJSON

```go
func (n *NullFloat64) UnmarshalJSON(b []byte) error
```
UnmarshalJSON implements the json.Unmarshaler interface.

#### type NullInt64

```go
type NullInt64 struct {
    sql.NullInt64
}
```

NullInt64 is a type that can be null or an int

#### func  Int64

```go
func Int64(i int64) NullInt64
```
Int64 creates a valid NullInt64

#### func (*NullInt64) Get

```go
func (n *NullInt64) Get() *int64
```
Get returns nil or underlying int64 value

#### func (*NullInt64) MarshalJSON

```go
func (n *NullInt64) MarshalJSON() ([]byte, error)
```
MarshalJSON implements the json.Marshaler interface.

#### func (*NullInt64) UnmarshalJSON

```go
func (n *NullInt64) UnmarshalJSON(b []byte) error
```
UnmarshalJSON implements the json.Unmarshaler interface.

#### type NullString

```go
type NullString struct {
    sql.NullString
}
```

NullString is a type that can be null or a string

#### func  String

```go
func String(s string) NullString
```
String creates a valid NullString

#### func (*NullString) Get

```go
func (n *NullString) Get() *string
```
Get returns nil or underlying string value

#### func (*NullString) MarshalJSON

```go
func (n *NullString) MarshalJSON() ([]byte, error)
```
MarshalJSON implements the json.Marshaler interface.

#### func (*NullString) UnmarshalJSON

```go
func (n *NullString) UnmarshalJSON(b []byte) error
```
UnmarshalJSON implements the json.Unmarshaler interface.

#### type NullTime

```go
type NullTime struct {
    pq.NullTime
}
```

NullTime is a type that can be null or a time.Time

#### func  Time

```go
func Time(t time.Time) NullTime
```
Time creates a valid NullTime

#### func (*NullTime) Get

```go
func (n *NullTime) Get() *time.Time
```
Get returns nil or underlying time.Time value

#### func (*NullTime) MarshalJSON

```go
func (n *NullTime) MarshalJSON() ([]byte, error)
```
MarshalJSON implements the json.Marshaler interface.

#### func (*NullTime) UnmarshalJSON

```go
func (n *NullTime) UnmarshalJSON(b []byte) error
```
UnmarshalJSON implements the json.Unmarshaler interface.
