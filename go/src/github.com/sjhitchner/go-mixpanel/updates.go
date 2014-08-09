package mixpanel

import (
	"time"
)

const (
	MIXPANEL_UPDATE_TOKEN       = "$token"
	MIXPANEL_UPDATE_DISTINCT_ID = "$distinct_id"
)

// Event Struct used to create events
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$ip": "123.123.123.123",
//     "$set": {
//         "Address": "1313 Mockingbird Lane"
//     }
// }
type Update struct {
	DistinctId string    `json:"$distinct_id"`
	Token      string    `json:"$token"`
	Ip         string    `json:"$ip,omitempty"`
	Time       int64     `json:"$time,omitempty"`
	IgnoreTime bool      `json:"$ignore_time,omitempty"`
	Set        Operation `json:"$set,omitempty"`
	SetOnce    Operation `json:"$set_once,omitempty"`
	Add        Operation `json:"$add,omitempty"`
	Unset      Operation `json:"$unset,omitempty"`
	Append     Operation `json:"$append,omitempty"`
	Union      Operation `json:"$union,omitempty"`
	Delete     Operation `json:"$delete,omitempty"`
}

type Operation interface {
	Operation() string
}

func NewUpdate(distintId string) *Update {
	return &Update{
		DistinctId: distintId,
	}
}

func (e *Update) setToken(token string) {
	e.Token = token
}

func (e *Update) SetIp(ip string) {
	e.Ip = ip
}

func (e *Update) SetTime(t time.Time) {
	e.Time = t.UTC().UnixNano() / 1000000
}

func (e *Update) SetIgnoreTime() {
	e.IgnoreTime = true
}

func (e *Update) SetOperation(operation Operation) {
	switch operation.(type) {
	case Set:
		e.Set = operation
	case SetOnce:
		e.SetOnce = operation
	case Add:
		e.Add = operation
	case Unset:
		e.Unset = operation
	case Append:
		e.Append = operation
	case Union:
		e.Union = operation
	case Delete:
		e.Delete = operation
	}
}

// $set
// object
// Takes a JSON object containing names and values of profile properties. If the profile does not exist, it creates it with these properties. If it does exist, it sets the properties to these values, overwriting existing values.
// sets the "Address" and "Birthday"
// properties of user 13793
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$ip": "123.123.123.123",
//     "$set": {
//         "Address": "1313 Mockingbird Lane",
//         "Birthday": "1948-01-01"
//     }
// }
type Set map[string]interface{}

func NewSet() Set {
	return make(map[string]interface{})
}

func (o Set) AddProperty(key string, value interface{}) {
	switch t := value.(type) {
	case time.Time:
		o[key] = time2String(t)
	default:
		o[key] = value
	}
}

func (o Set) Operation() string {
	return "$set"
}

// $set_once
// object
// Works just like "$set", except it will not overwrite existing property values. This is useful for properties like "First login date".
// This sets the "First login date" property of user 13793
// if and only if it has never been set before
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$set_once": {
//         "First login date": "2013-04-01T13:20:00"
//     }
// }
type SetOnce map[string]interface{}

func NewSetOnce() SetOnce {
	return make(map[string]interface{})
}

func (o SetOnce) AddProperty(key string, value interface{}) {
	switch t := value.(type) {
	case time.Time:
		o[key] = time2String(t)
	default:
		o[key] = value
	}
}

func (o SetOnce) Operation() string {
	return "$set_once"
}

// $add
// object
// Takes a JSON object containing keys and numerical values. When processed, the property values are added to the existing values of the properties on the profile.
// If the property is not present on the profile, the value will be added to 0. It is possible to decrement by calling "$add" with negative values. This is useful for maintaining the values of properties like "Number of Logins" or "Files Uploaded".
// // This adds 12 to a running total of
// // Coins Gathered for user 13793
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$add": { "Coins Gathered": 12 }
// }
type Add map[string]int64

func NewAdd() Add {
	return make(map[string]int64)
}

func (o Add) Increment(key string, value int) {
	o[key] = int64(value)
}

func (o Add) Increment64(key string, value int64) {
	o[key] = value
}

func (o Add) Operation() string {
	return "$add"
}

// $append
// object
// Takes a JSON object containing keys and values, and appends each to a list associated with the corresponding property name. $appending to a property that doesn't exist will result in assigning a list with one element to that property.
// // This adds "Bubble Lead" to
// // the list "Power Ups" for user 13793
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$append": { "Power Ups": "Bubble Lead" }
// }
type Append map[string]interface{}

func NewAppend() Append {
	return make(map[string]interface{})
}

func (o Append) AddProperty(key string, value interface{}) {
	switch t := value.(type) {
	case time.Time:
		o[key] = time2String(t)
	default:
		o[key] = value
	}
}

func (o Append) Operation() string {
	return "$append"
}

// $union
// object
// Takes a JSON object containing keys and list values. The list values in the request are merged with the existing list on the user profile, ignoring duplicate list values.
// // This combines ["socks", "shirts"] with the existing values for the "Items purchased"
// // list for user 13793, also ensuring that the list values will only appear once in
// // the merged list.
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$union": { "Items purchased": ["socks", "shirts"] }
// }
type Union map[string][]interface{}

func NewUnion() Union {
	return make(map[string][]interface{})
}

func (o Union) AddUnion(key string, values ...interface{}) {
	//TODO attribute already exists in map?
	//union, ok := m[key]
	//if !ok {
	union := make([]interface{}, 0, len(values))
	//}
	for _, value := range values {
		switch t := value.(type) {
		case time.Time:
			union = append(union, time2String(t))
		default:
			union = append(union, value)
		}
	}
	o[key] = union
}

func (o Union) Operation() string {
	return "$union"
}

// $unset
// list
// Takes a JSON list of string property names, and permanently removes the properties and their values from a profile.
// // This removes the property "Days Overdue" from user 13793
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$unset": [ "Days Overdue" ]
// }
type Unset []string

func NewUnset(args ...string) Unset {
	us := make([]string, 0, 1)
	for _, key := range args {
		us = append(us, key)
	}
	return us
}

func (o Unset) Remove(key string) {
	o = append(o, key)
}

func (o Unset) Operation() string {
	return "$unset"
}

// $delete
// string
// Permanently delete the profile from Mixpanel, along with all of its properties. The value is ignored - the profile is determined by the $distinct_id from the request itself.
// // This removes the user 13793 from Mixpanel
// {
//     "$token": "36ada5b10da39a1347559321baf13063",
//     "$distinct_id": "13793",
//     "$delete": ""
// }
type Delete struct {
}

func NewDelete() Delete {
	return Delete{}
}

func (o Delete) Operation() string {
	return "$delete"
}
