package sshkey

import (
	"encoding/json"
	"net/http"
)

// Handler generates the key pair and encodes the keys
func Handler(w http.ResponseWriter, req *http.Request) {
	pub, priv, err := Generate()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	keyPair := make(map[string]interface{})
	keyPair["public"] = pub
	keyPair["private"] = priv

	err = json.NewEncoder(w).Encode(keyPair)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
	}

}
