package main

import (
	"bytes"
	"flag"
	"fmt"
	"html/template"
	"koding/artifact"
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
	Name        = "gowebserver"
	flagConfig  = flag.String("c", "", "Configuration profile from file")
	log         = logging.NewLogger(Name)
	kodingGroup *models.Group
	conf        *config.Config
)

type HomeContent struct {
	Version     string
	Runtime     config.RuntimeOptions
	User        LoggedInUser
	Title       string
	Description string
	ShareUrl    string
}

type LoggedInUser struct {
	Account    *models.Account
	Machines   []*modelhelper.MachineContainer
	Workspaces []*models.Workspace
	Group      *models.Group
	Username   string
	SessionId  string
}

func initialize() {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		log.Critical("Please define config file with -c")
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	var err error
	kodingGroup, err = modelhelper.GetGroup("koding")
	if err != nil {
		log.Critical("Couldn't fetching `koding` group: %v", err)
		panic(err)
	}
}

func main() {
	initialize()

	url := fmt.Sprintf(":%d", conf.Gowebserver.Port)

	log.Info("Starting gowebserver on %v", url)

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	http.ListenAndServe(url, nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil {
		if err != http.ErrNoCookie {
			log.Error("Couldn't fetch the cookie: %s", err)
		}
		log.Info("loggedout page took: %s", time.Since(start))
		renderLoggedOutHome(w)

		return
	}

	if cookie.Value == "" {
		log.Info("loggedout page took: %s", time.Since(start))
		renderLoggedOutHome(w)

		return
	}

	clientId := cookie.Value

	session, err := modelhelper.GetSession(clientId)
	if err != nil {
		log.Error("Couldn't fetch session with clientId %s: %s", clientId, err)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w) // TODO: clean up session

		return
	}

	username := session.Username
	if username == "" {
		log.Error("Username is empty for session with clientId: %s", clientId)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w)

		return
	}

	//----------------------------------------------------------
	// Account
	//----------------------------------------------------------

	account, err := modelhelper.GetAccount(username)
	if err != nil {
		log.Error("Couldn't fetch account with username %s: %s", username, err)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w)

		return
	}

	if account.Type != "registered" {
		log.Info("loggedout page took: %s", time.Since(start))
		renderLoggedOutHome(w)

		return
	}

	//----------------------------------------------------------
	// Machines
	//----------------------------------------------------------

	user, err := modelhelper.GetUser(username)
	if err != nil {
		log.Error("Couldn't get user of %s: %s", username, err)
		log.Info("loggedout page took: %s", time.Since(start))

		renderLoggedOutHome(w)
	}

	machines, err := modelhelper.GetMachines(user.ObjectId)
	if err != nil {
		log.Error("Couldn't fetch machines: %s", err)
		machines = []*modelhelper.MachineContainer{}
	}

	//----------------------------------------------------------
	// Workspaces
	//----------------------------------------------------------

	workspaces, err := modelhelper.GetWorkspaces(account.Id)
	if err != nil {
		log.Error("Couldn't fetch workspaces: %s", err)
		workspaces = []*models.Workspace{}
	}

	loggedInUser := LoggedInUser{
		SessionId:  clientId,
		Group:      kodingGroup,
		Workspaces: workspaces,
		Machines:   machines,
		Account:    account,
		Username:   username,
	}

	renderLoggedInHome(w, loggedInUser)

	log.Info("loggedin page took: %s", time.Since(start))
}

func renderLoggedInHome(w http.ResponseWriter, u LoggedInUser) {
	homeTmpl := template.Must(template.New("home").Parse(templates.LoggedInHome))

	hc := buildHomeContent()
	hc.Runtime = conf.Client.RuntimeOptions
	hc.User = u

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		log.Error("Failed to render loggedin page: %s", err)
		renderLoggedOutHome(w)

		return
	}

	fmt.Fprintf(w, buf.String())
}

func renderLoggedOutHome(w http.ResponseWriter) {
	homeTmpl := template.Must(template.New("home").Parse(templates.LoggedOutHome))

	hc := buildHomeContent()

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		log.Error("Failed to render loggedout page: %s", err)
	}

	fmt.Fprintf(w, buf.String())
}

func buildHomeContent() HomeContent {
	hc := HomeContent{
		Version:  conf.Version,
		ShareUrl: conf.Client.RuntimeOptions.MainUri,
	}
	hc.Title = "Koding | Say goodbye to your localhost and write code in the cloud"
	hc.Description = "Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go,  Java, NodeJS, PHP, C, C++, Perl, Python, etc."

	return hc
}
