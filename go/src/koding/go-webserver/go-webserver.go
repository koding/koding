package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/go-webserver/templates"
	"koding/tools/config"
	"net/http"
	"runtime"
	"time"

	"github.com/koding/logging"
)

var (
	flagConfig      = flag.String("c", "", "Configuration profile from file")
	flagTemplates   = flag.String("t", "", "Change template directory")
	conf            *config.Config
	kodingGroupJson []byte
	log             = logging.NewLogger("gowebserver")
)

func initialize() {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		log.Critical("Please define config file with -c")
	}

	if *flagTemplates == "" {
		log.Critical("Please define template folder with -t")
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	kodingGroup, err := modelhelper.GetGroup("koding")
	if err != nil {
		log.Critical("Couldn't fetching `koding` group: %v", err)
		panic(err)
	}

	kodingGroupJson, err = json.Marshal(kodingGroup)
	if err != nil {
		log.Critical("Couldn't marshalling `koding` group: %v", err)
		panic(err)
	}
}

func main() {
	initialize()

	url := fmt.Sprintf(":%d", conf.Gowebserver.Port)

	http.HandleFunc("/", HomeHandler)
	http.ListenAndServe(url, nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil || cookie.Value == "" {
		log.Info("loggedout page took: %s", time.Since(start))
		renderLoggedOutHome(w)

		return
	}

	clientId := cookie.Value

	session, err := modelhelper.GetSession(clientId)
	if err != nil {
		log.Error("Failed to fetch session with clientId: %s", clientId)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w) // TODO: clean up session

		return
	}

	username := session.Username
	if username == "" {
		log.Error("username is empty for session with clientId: %s", clientId)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w)

		return
	}

	//----------------------------------------------------------
	// Account
	//----------------------------------------------------------

	account, err := modelhelper.GetAccount(username)
	if err != nil {
		log.Error("Failed to fetch account with username: %s", username)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w)

		return
	}

	if account.Type != "registered" {
		log.Info("loggedout page took: %s", time.Since(start))
		renderLoggedOutHome(w)

		return
	}

	accountJson, err := json.Marshal(account)
	if err != nil {
		log.Error("Couldn't marshal account: %s", err)
	}

	//----------------------------------------------------------
	// Machines
	//----------------------------------------------------------

	machines, err := modelhelper.GetMachines(username)
	if err != nil {
		log.Error("Couldn't fetch machines: %s", err)
		machines = []*modelhelper.MachineContainer{}
	}

	machinesJson, err := json.Marshal(machines)
	if err != nil {
		log.Error("Couldn't marshal account: %s", err)
	}

	//----------------------------------------------------------
	// Workspaces
	//----------------------------------------------------------

	workspaces, err := modelhelper.GetWorkspaces(account.Id)
	if err != nil {
		log.Error("Couldn't fetch workspaces: %s", err)
		workspaces = []*models.Workspace{}
	}

	workspacesJson, err := json.Marshal(workspaces)
	if err != nil {
		log.Error("Couldn't marshal workspaces: %s", err)
	}

	renderLoggedInHome(w,
		accountJson, machinesJson, workspacesJson, kodingGroupJson,
	)

	log.Info("loggedin page took: %s", time.Since(start))
}

func renderLoggedInHome(w http.ResponseWriter, account, machines, workspaces, group []byte) {
	runtime, err := json.Marshal(conf.Client.RuntimeOptions)
	if err != nil {
		log.Error("Couldn't marshal runtime options: %s", err)
		runtime = []byte("{}")
	}

	version := conf.Version
	html := fmt.Sprintf(templates.LoggedInHome,
		version, version, //css
		runtime,
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
