package main

import (
	"fmt"
	"koding/kite"
	"koding/kite/protocol"
	"testing"
	"time"
)

// Test 2 way communication between kites.
func TestDatastore(t *testing.T) {
	options := &kite.Options{
		Kitename:    "datastore",
		Version:     "1",
		Port:        "3636",
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "127.0.0.1",
	}

	datastoreKite := New(options)
	datastoreKite.Start()

	clientOptions := &kite.Options{
		Kitename:    "application",
		Version:     "1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
		Username:    "devrim",
	}

	k := kite.New(clientOptions)
	k.Start()

	query := protocol.KontrolQuery{
		Username:    "devrim",
		Environment: "development",
		Name:        "datastore",
	}

	// To demonstrate we can receive notifications matcing to our query.
	onEvent := func(e *kite.Event) {
		fmt.Printf("--- kite event: %#v\n", e)
	}

	kites, err := k.Kontrol.GetKites(query, onEvent)
	if err != nil {
		fmt.Println(err)
		return
	}

	datastoreClient := kites[0]
	err = datastoreClient.Dial()
	if err != nil {
		fmt.Println("Cannot connect to remote datastore kite")
		return
	}

	set := func(k string, v string) {
		response, err := datastoreClient.Call("set", []string{k, v})
		if err != nil {
			fmt.Println(err)
			return
		}

		var result bool
		err = response.Unmarshal(&result)
		if err != nil {
			fmt.Println(err)
			return
		}
	}

	get := func(k string) (error, string) {
		response, err := datastoreClient.Call("get", k)
		if err != nil {
			fmt.Println(err)
			return err, ""
		}

		var result string
		err = response.Unmarshal(&result)
		if err != nil {
			fmt.Println(err)
			return err, ""
		}

		return err, result
	}

	value := fmt.Sprintf("value_%s", time.Now().UTC())
	set("foo", value)
	_, v := get("foo")
	if v != value {
		t.Errorf(err.Error())
	}

	// double checking if the value has changed.
	value = fmt.Sprintf("value_%s", time.Now().UTC())
	set("foo", value)
	_, v = get("foo")
	if v != value {
		t.Errorf(err.Error())
	}

}
