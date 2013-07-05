package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/kontrol/kontroldaemon/clientconfig"
	"labix.org/v2/mgo/bson"
	"net/http"
	"sort"
	"strconv"
)

type DeployPostMessage struct {
	Build  *string
	Git    *string
	Config *string
}

func GetClients(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("GET /deployments")
	clients := clientDB.GetClients()

	data, err := json.MarshalIndent(clients, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))
}

func GetClient(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	build := vars["build"]
	fmt.Printf("GET /deployments/%s\n", build)

	client := clientconfig.ServerInfo{}
	clients := make([]clientconfig.ServerInfo, 0)

	if build == "latest" {
		iter := clientDB.Collection.Find(nil).Iter()
		for iter.Next(&client) {
			clients = append(clients, client)
		}

		if len(clients) == 0 {
			io.WriteString(writer, "[]") // return empty slice
			return
		}

		builds := make([]int, len(clients))

		for i, val := range clients {
			builds[i], _ = strconv.Atoi(val.BuildNumber)
		}

		sort.Ints(builds)
		latestBuild := builds[len(builds)-1] // get largest build number
		for _, val := range clients {
			build, _ := strconv.Atoi(val.BuildNumber)

			if latestBuild == build {
				data, err := json.MarshalIndent(val, "", "  ")
				if err != nil {
					io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
					return
				}
				writer.Write([]byte(data))
				return
			}
		}
	}

	query := bson.M{"buildnumber": build}
	iter := clientDB.Collection.Find(query).Iter()
	for iter.Next(&client) {
		data, err := json.MarshalIndent(client, "", "  ")
		if err != nil {
			io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
			return
		}

		writer.Write([]byte(data))
		return
	}

}

func CreateClient(writer http.ResponseWriter, req *http.Request) {
	fmt.Println("POST /deployments")
	var msg DeployPostMessage
	var build string
	var git string
	var config string

	body, _ := ioutil.ReadAll(req.Body)

	err := json.Unmarshal(body, &msg)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Build != nil {
		build = *msg.Build
	} else {
		err := "aborting. no 'build' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Git != nil {
		git = *msg.Git
	} else {
		err := "aborting. no 'git' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	if msg.Config != nil {
		config = *msg.Config
	} else {
		err := "aborting. no 'config' available"
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	client := clientconfig.ServerInfo{
		BuildNumber: build,
		GitBranch:   git,
		ConfigUsed:  config,
		Config:      nil,
		Hostname:    clientconfig.Hostname{},
		IP:          clientconfig.IP{},
	}

	clientDB.AddClient(client)

	url := fmt.Sprintf("deploy info posted build: %s, git branch: %s and config used: %s", build, git, config)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return

}

func DeleteClient(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	build := vars["build"]
	fmt.Printf("DELETE\t/deployments/%s\n", build)

	err := clientDB.DeleteClient(build)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	resp := fmt.Sprintf("build '%s' is deleted", build)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
