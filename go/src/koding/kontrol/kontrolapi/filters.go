package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"koding/db/mongodb/modelhelper"
	"labix.org/v2/mgo/bson"
	"net/http"
)

func GetFilterByID(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	id := vars["id"]

	res, err := modelhelper.GetFilterByID(bson.ObjectIdHex(id))
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
