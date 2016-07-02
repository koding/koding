package sshkeys

import (
	"errors"
	"log"

	"github.com/koding/kite"
)

// AddOptions is the option struct for the Add method of klient.
type AddOptions struct {
	Username string `json:"username"`
	Keys     []string
	Override bool
}

// List returns a list of all keys with their respective fingerrpints for the
// callers username. Fingerprints are useful to delete a key.
func List(r *kite.Request) (interface{}, error) {
	fullKeys, err := ListKeys(r.Username, FullKeys)
	if err != nil {
		return nil, err
	}

	if len(fullKeys) == 0 {
		return nil, errors.New("no ssh keys found")
	}

	keys := make(map[string]string, 0)
	for _, key := range fullKeys {
		fingerprint, _, err := KeyFingerprint(key)
		if err != nil {
			log.Println("sshkeys.List: %s", err)
			continue
		}

		keys[fingerprint] = key
	}

	return keys, nil
}

// Add adds the given keys to the authorized_keys file. If override is given,
// it replaces the current authorized_keys with the given keys.
func Add(r *kite.Request) (interface{}, error) {
	var opts AddOptions

	if err := r.Args.One().Unmarshal(&opts); err != nil {
		return nil, err
	}

	if len(opts.Keys) == 0 {
		return nil, errors.New("keys argument list is empty")
	}

	username := opts.Username
	if username == "" {
		username = r.Username
	}

	if opts.Override {
		if err := ReplaceKeys(username, opts.Keys...); err != nil {
			return nil, err
		}
	} else {
		if err := AddKeys(username, opts.Keys...); err != nil {
			return nil, err
		}
	}

	return true, nil
}

// Delete deletes the given keys associated with the fingerprints.
func Delete(r *kite.Request) (interface{}, error) {
	var params struct {
		Fingerprints []string
	}

	if err := r.Args.One().Unmarshal(&params); err != nil {
		return nil, err
	}

	if len(params.Fingerprints) == 0 {
		return nil, errors.New("fingerprints argument list is empty")
	}

	if err := DeleteKeys(r.Username, params.Fingerprints...); err != nil {
		return nil, err
	}

	return true, nil
}
