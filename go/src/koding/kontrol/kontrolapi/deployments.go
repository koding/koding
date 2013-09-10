package main

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"io"
	"io/ioutil"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"

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
	clients := modelhelper.GetClients()

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

	if build == "latest" {
		clients := modelhelper.GetClients()

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

	client, err := modelhelper.GetClient(build)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	data, err := json.MarshalIndent(client, "", "  ")
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	writer.Write([]byte(data))

}

func CreateClient(writer http.ResponseWriter, req *http.Request) {
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

	client := models.ServerInfo{
		BuildNumber: build,
		GitBranch:   git,
		ConfigUsed:  config,
		Config:      nil,
		Hostname:    models.Hostname{},
		IP:          models.IP{},
	}

	modelhelper.AddClient(client)

	url := fmt.Sprintf("deploy info posted build: %s, git branch: %s and config used: %s", build, git, config)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", url))
	return

}

func DeleteClient(writer http.ResponseWriter, req *http.Request) {
	vars := mux.Vars(req)
	build := vars["build"]

	err := modelhelper.DeleteClient(build)
	if err != nil {
		io.WriteString(writer, fmt.Sprintf("{\"err\":\"%s\"}\n", err))
		return
	}

	resp := fmt.Sprintf("build '%s' is deleted", build)
	io.WriteString(writer, fmt.Sprintf("{\"res\":\"%s\"}\n", resp))
	return
}
