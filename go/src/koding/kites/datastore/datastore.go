// this provides a simple datastore for kites just with get/set methods.
// mongodb has 24k number of collection limit in a single database
// http://stackoverflow.com/questions/9858393/limits-of-number-of-collections-in-databases
// thats why we have a single collection and use single index
// though instead of using a single collection  we can use different strategies, like
// multiple database, single collections
// multiple database, multiple collections
// etc... to make it a bit more performant.
// though mongodb has an auto sharding setup, http://docs.mongodb.org/manual/sharding/
// which should be considered first. or use another datastore like elasticsearch, cassandra etc.
// to handle the sharding on database level.
// thats why we only have one strategy only for now, to get the ball rolling.

package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kite"
)

var port = flag.String("port", "", "port to bind itself")

func main() {
	flag.Parse()

	options := &kite.Options{
		Kitename:    "datastore",
		Version:     "0.0.1",
		Port:        *port,
		Region:      "localhost",
		Environment: "development",
		PublicIP:    "127.0.0.1",
	}

	k := New(options)
	modelhelper.EnsureKeyValueIndexes()
	k.Run()
}

func New(options *kite.Options) *kite.Kite {
	k := kite.New(options)
	k.HandleFunc("set", Set)
	k.HandleFunc("get", Get)
	return k
}

func Set(r *kite.Request) (interface{}, error) {
	kv, err := r.Args.Array()
	if err != nil {
		return nil, err
	}

	key, ok := kv[0].(string)
	if !ok {
		return nil, fmt.Errorf("Invalid string: %s", kv[0])
	}

	value, ok := kv[1].(string)
	if !ok {
		return nil, fmt.Errorf("Invalid string: %s", kv[1])
	}

	keyValue := modelhelper.NewKeyValue(r.Username, r.RemoteKite.Name, r.RemoteKite.Environment, key)
	keyValue.Value = value
	err = modelhelper.UpsertKeyValue(keyValue)

	result := true
	if err != nil {
		result = false
	}

	return result, nil
}

func Get(r *kite.Request) (interface{}, error) {
	key, err := r.Args.String()
	if err != nil {
		return nil, err
	}

	kv, err := modelhelper.GetKeyValue(r.Username, r.RemoteKite.Name, r.RemoteKite.Environment, key)
	if err != nil {
		return nil, err
	}

	return kv.Value, nil
}
