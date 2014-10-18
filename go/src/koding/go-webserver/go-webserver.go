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
	Name              = "gowebserver"
	kodingTitle       = "Koding | Say goodbye to your localhost and write code in the cloud."
	kodingDescription = "Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go, Java, NodeJS, PHP, C, C++, Perl, Python, etc."

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	log        = logging.NewLogger(Name)

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

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.Gowebserver.Port)
	log.Info("Starting gowebserver on: %v", url)

	http.ListenAndServe(url, nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	cookie, err := r.Cookie("clientId")
	if err != nil {
		if err != http.ErrNoCookie {
			log.Error("Couldn't fetch 'clientId' cookie value: %s", err)
		}

		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	if cookie.Value == "" {
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	clientId := cookie.Value

	session, err := modelhelper.GetSession(clientId)
	if err != nil {
		log.Error("Couldn't fetch session with clientId %s: %s", clientId, err)
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	username := session.Username
	if username == "" {
		log.Error("Username is empty for session with clientId: %s", clientId)
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	//----------------------------------------------------------
	// Account
	//----------------------------------------------------------

	account, err := modelhelper.GetAccount(username)
	if err != nil {
		log.Error("Couldn't fetch account with username %s: %s", username, err)
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	if account.Type != "registered" {
		log.Error(
			"Account type: %s is not 'registered' for %s's session.",
			account.Type, username,
		)
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)

		return
	}

	//----------------------------------------------------------
	// Machines
	//----------------------------------------------------------

	user, err := modelhelper.GetUser(username)
	if err != nil {
		log.Error("Couldn't get user of %s: %s", username, err)
		log.Info("loggedout page took: %s", time.Since(start))

		expireCookie(cookie)
		writeLoggedOutHomeToResp(w)
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

	writeLoggedInHomeToResp(w, loggedInUser)

	log.Info("loggedin page took: %s", time.Since(start))
}

func writeLoggedInHomeToResp(w http.ResponseWriter, u LoggedInUser) {
	homeTmpl := buildHomeTemplate(templates.LoggedInHome)

	hc := buildHomeContent()
	hc.Runtime = conf.Client.RuntimeOptions
	hc.User = u

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		log.Error("Failed to render loggedin page: %s", err)
		writeLoggedOutHomeToResp(w)

		return
	}

	fmt.Fprintf(w, buf.String())
}

func writeLoggedOutHomeToResp(w http.ResponseWriter) {
	homeTmpl := buildHomeTemplate(templates.LoggedOutHome)

	hc := buildHomeContent()

	var buf bytes.Buffer
	if err := homeTmpl.Execute(&buf, hc); err != nil {
		log.Error("Failed to render loggedout page: %s", err)
	}

	fmt.Fprintf(w, buf.String())
}

func buildHomeContent() HomeContent {
	hc := HomeContent{
		Version:     conf.Version,
		ShareUrl:    conf.Client.RuntimeOptions.MainUri,
		Title:       kodingTitle,
		Description: kodingDescription,
	}

	return hc
}

func buildHomeTemplate(content string) *template.Template {
	homeTmpl := template.Must(template.New("home").Parse(content))
	headerTmpl := template.Must(template.New("header").Parse(templates.Header))
	analyticsTmpl := template.Must(template.New("analytics").Parse(templates.Analytics))

	homeTmpl.AddParseTree("header", headerTmpl.Tree)
	homeTmpl.AddParseTree("analytics", analyticsTmpl.Tree)

	return homeTmpl
}

func expireCookie(cookie *http.Cookie) {
	cookie.Expires = time.Now()
}
