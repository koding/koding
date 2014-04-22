package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"koding/db/mongodb/modelhelper"
	"net/http"
)

func GetRestrictionByDomain(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	domain := vars["domain"]

	res, err := modelhelper.GetRestrictionByDomain(domain)
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}

	data, err := json.MarshalIndent(res, "", "  ")
	if err != nil {
		http.Error(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err), http.StatusBadRequest)
		return
	}
	writer.Write([]byte(data))
}
