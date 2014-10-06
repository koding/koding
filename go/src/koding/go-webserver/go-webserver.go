package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/go-webserver/templates"
	"koding/tools/config"
	"log"
	"net/http"
	"time"
)

var (
	flagConfig       = flag.String("c", "", "Configuration profile from file")
	flagTemplates    = flag.String("t", "", "Change template directory")
	conf             *config.Config
	kodingGroupJson  []byte
	isLoggedInOnLoad = true
	usePremiumBroker = false
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

	kodingGroupJson, err = json.Marshal(kodingGroup)
	if err != nil {
		fmt.Println("Error marshalling Koding group", err)
	}
}

func main() {
	initialize()

	http.HandleFunc("/", HomeHandler)
	http.ListenAndServe(":6500", nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil || cookie.Value == "" {
		renderLoggedOutHome(w)
		return
	}

	session, err := modelhelper.GetSession(cookie.Value)
	if err != nil {
		renderLoggedOutHome(w) // TODO: clean up session
		return
	}

	//----------------------------------------------------------
	// Account
	//----------------------------------------------------------

	username := session.Username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		renderLoggedOutHome(w)
		return
	}

	if account.Type != "registered" {
		renderLoggedOutHome(w)
		return
	}

	accountJson, err := json.Marshal(account)
	if err != nil {
		fmt.Println("Error marshalling account", err)
	}

	//----------------------------------------------------------
	// Machines
	//----------------------------------------------------------

	machines, err := modelhelper.GetMachines(username)
	if err != nil {
		fmt.Println("Error fetching machines", err)
		machines = []*modelhelper.MachineContainer{}
	}

	machinesJson, err := json.Marshal(machines)
	if err != nil {
		fmt.Println("Error marshalling account", err)
	}

	//----------------------------------------------------------
	// Workspaces
	//----------------------------------------------------------

	workspaces, err := modelhelper.GetWorkspaces(account.Id)
	if err != nil {
		fmt.Println("Error fetching workspaces", err)
		workspaces = []*models.Workspace{}
	}

	workspacesJson, err := json.Marshal(workspaces)
	if err != nil {
		fmt.Println("Error marshalling workspaces", err)
	}

	renderLoggedInHome(w,
		accountJson, machinesJson, workspacesJson, kodingGroupJson,
	)

	fmt.Println("Request to go-webserver took", time.Since(start))
}

func renderLoggedInHome(w http.ResponseWriter, account, machines, workspaces, group []byte) {
	runtime, err := json.Marshal(conf.Client.RuntimeOptions)
	if err != nil {
		fmt.Println("Error marshalling runtime options", err)
		runtime = []byte("1")
	}

	version := conf.Version
	html := fmt.Sprintf(templates.LoggedInHome,
		version, version, //css
		runtime, isLoggedInOnLoad, usePremiumBroker,
		account, machines, workspaces, group,
		version, version, version, //json
	)

	fmt.Fprintf(w, html)
}

func renderLoggedOutHome(w http.ResponseWriter) {
	version := conf.Version
	html := fmt.Sprintf(templates.LoggedOutHome,
		version, version, //css
		version, version, version, version, //js
	)

	fmt.Fprintf(w, html)
}
