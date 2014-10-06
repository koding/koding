package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"net/http"
	"time"

	"github.com/hoisie/mustache"
)

var (
	flagConfig      = flag.String("c", "", "Configuration profile from file")
	flagTemplates   = flag.String("t", "", "Change template directory")
	conf            *config.Config
	kodingGroupJson []byte
)

func initialize() {
	flag.Parse()
	if *flagConfig == "" {
		log.Fatal("Please define config file with -c")
	}

	if *flagTemplates == "" {
		log.Fatal("Please define template folder with -t")
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	kodingGroup, err := modelhelper.GetGroup("koding")
	if err != nil {
		panic(err)
	}

	kodingGroupJson, _ = json.Marshal(kodingGroup)
}

func main() {
	initialize()

	http.HandleFunc("/", HomeHandler)
	http.ListenAndServe(":6500", nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil {
		fmt.Println(">>>>>>> no cookie")
		output := loggedOut()

		fmt.Fprintf(w, output)
		fmt.Println(time.Since(start))
		return
	}

	session, err := modelhelper.GetSession(cookie.Value)
	if err != nil {
		// TODO: clean up session
		fmt.Println(">>>>>>> no session")
		output := loggedOut()

		fmt.Fprintf(w, output)
		fmt.Println(time.Since(start))

		return
	}

	username := session.Username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	if account.Type != "registered" {
		fmt.Println(">>>>>>> account not registered")
		output := loggedOut()

		fmt.Fprintf(w, output)
		fmt.Println(time.Since(start))

		return
	}

	machines, err := modelhelper.GetMachines(username)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	workspaces, err := modelhelper.GetWorkspaces(account.Id)
	if err != nil {
		fmt.Println(">>>>>>>>", err)
		return
	}

	accountJson, _ := json.Marshal(account)
	machinesJson, _ := json.Marshal(machines)
	workspacesJson, _ := json.Marshal(workspaces)

	index := buildIndex(accountJson, machinesJson, workspacesJson, kodingGroupJson)

	fmt.Fprintf(w, index)
	fmt.Println(time.Since(start))
}

func loggedOut() string {
	indexFilePath := *flagTemplates + "loggedout.html.mustache"
	output := mustache.RenderFile(indexFilePath, map[string]interface{}{
		"version": conf.Version,
	})

	return output
}

func buildIndex(accountJson, machinesJson, workspacesJson, kodingGroupJson []byte) string {
	runtimeJson, err := json.Marshal(conf.Client.RuntimeOptions)
	if err != nil {
		fmt.Println("<<<<<", err)
	}

	indexFilePath := *flagTemplates + "index.html.mustache"
	output := mustache.RenderFile(indexFilePath, map[string]interface{}{
		"KD":               string(runtimeJson),
		"isLoggedInOnLoad": true,
		"usePremiumBroker": false,
		"userAccount":      string(accountJson),
		"userMachines":     string(machinesJson),
		"userWorkspaces":   string(workspacesJson),
		"currentGroup":     string(kodingGroupJson),
		"version":          conf.Version,
	})

	return output
}
