package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"html/template"
	"io/ioutil"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/logger"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"time"

	"github.com/gorilla/sessions"
)

var log = logger.New("overview")

func NewServerInfo() *ServerInfo {
	return &ServerInfo{
		BuildNumber: "",
		GitBranch:   "",
		GitCommit:   "",
		ConfigUsed:  "",
		Config:      ConfigFile{},
		Hostname:    Hostname{},
		IP:          IP{},
	}
}

var (
	kodingHost string
	socialHost string
	apiUrl     = "http://kontrol0.sj.koding.com:80" // default

	templates *template.Template

	flagConfig    = flag.String("c", "", "Configuration profile from file")
	flagTemplates = flag.String("template", "go/templates/overview", "Change template directory")
)

const uptimeLayout = "03:04:00"

var store = sessions.NewCookieStore([]byte("user"))

func main() {
	flag.Parse()
	if *flagConfig == "" {
		log.Fatal("Please define config file with -c")
	}

	templates = template.Must(template.ParseFiles(
		*flagTemplates+"/index.html",
		*flagTemplates+"/login.html",
	))

	conf := config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	var err error
	// used for kontrolapi
	apiHost := conf.Kontrold.Overview.ApiHost
	apiPort := conf.Kontrold.Overview.ApiPort
	apiUrl = "http://" + apiHost + ":" + strconv.Itoa(apiPort)

	// used to create the listener
	port := conf.Kontrold.Overview.Port

	// domain to be switched, like 'koding.com'
	kodingHost = conf.Kontrold.Overview.KodingHost
	socialHost = conf.Kontrold.Overview.SocialHost

	bootstrapFolder := "go/templates/overview/bootstrap/"

	http.HandleFunc("/", viewHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir(bootstrapFolder))))

	fmt.Printf("koding overview started at :%d\n", port)
	err = http.ListenAndServe(":"+strconv.Itoa(port), nil)
	if err != nil {
		log.Error("Error: %v", err)
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	var loginName string
	var switchMessage string
	var err error

	switch r.FormValue("operation") {
	case "logout":
		logoutHandler(w, r)
		return
	case "login":
		loginName, err = loginHandler(w, r)
		if err != nil {
			renderTemplate(w, "login", HomePage{LoginMessage: err.Error()})
			return
		}
		// continue because login was successfull
	case "switchVersion":
		loginName, err = checkSessionHandler(w, r)
		if err != nil {
			renderTemplate(w, "login", HomePage{LoginMessage: err.Error()})
			return
		}

		_, err := switchOperation(loginName, r)
		if err != nil {
			log.Error("Error: %v", err)
			renderTemplate(w, "login", HomePage{LoginMessage: err.Error()})
			return
		}
	case "newbuild":
		loginName, err = checkSessionHandler(w, r)
		if err != nil {
			renderTemplate(w, "login", HomePage{LoginMessage: err.Error()})
			return
		}

		branch, err := buildOperation(loginName, r)
		if err != nil {
			log.Error("could not build %v", err)
		} else {
			log.Info("build is created by '%s', for branch '%s'\n", loginName, branch)
		}
	default:
		loginName, err = checkSessionHandler(w, r)
		if err != nil {
			renderTemplate(w, "login", HomePage{LoginMessage: err.Error()})
			return
		}
	}

	build := r.FormValue("build")
	if build == "" || build == "current" {
		version, _ := currentVersion()
		build = version
	}

	workers, status, err := workerInfo(build)
	if err != nil {
		log.Error("Error: %v", err)
	}

	jenkins := jenkinsInfo()
	builds := buildsInfo()

	server, err := serverInfo(build)
	if err != nil {
		log.Error("Error: %v", err)
		server = NewServerInfo()
	}

	domain, err := domainInfo()
	if err != nil {
		log.Error("Error: %v", err)
	}

	s, b := keyLookup(domain.Proxy.Key)
	status.Koding.ServerHosts = s
	status.Koding.ServerLen = len(s) + 1
	status.Koding.BrokerHosts = b
	status.Koding.BrokerLen = len(b) + 1

	h := HomePage{
		Status:        status,
		Workers:       workers,
		Jenkins:       jenkins,
		Server:        server,
		Builds:        builds,
		LoginName:     loginName,
		SwitchMessage: switchMessage,
	}

	renderTemplate(w, "index", h)
	return
}

func logoutHandler(w http.ResponseWriter, r *http.Request) {
	session, err := store.Get(r, "userData")
	if err != nil {
		// reset username
		session.Values["userName"] = nil
		store.Save(r, w, session)
	} else {
		log.Error("Session could not be retrieved %v", err)
	}

	home := HomePage{LoginMessage: "Logged out!"}
	renderTemplate(w, "login", home) // go back to login page
}

func loginHandler(w http.ResponseWriter, r *http.Request) (string, error) {
	session, err := store.Get(r, "userData")
	if err != nil {
		log.Error("could not get session %v", err)
		return "", errors.New("Internal error")
	}

	loginName := r.PostFormValue("loginName")
	loginPass := r.PostFormValue("loginPass")

	if loginName == "" || loginPass == "" {
		return "", errors.New("Please enter a username and password")
	}

	// abort if password and username is not valid
	err = authenticateUser(loginName, loginPass)
	if err != nil {
		return "", err
	}

	session.Values["userName"] = loginName
	store.Save(r, w, session)
	return loginName, nil
}

func checkSessionHandler(w http.ResponseWriter, r *http.Request) (string, error) {
	session, err := store.Get(r, "userData")
	if err != nil {
		log.Error("could not get session %v", err)
		return "", errors.New("Internal error")
	}

	loginName, ok := session.Values["userName"]
	if !ok {
		return "", errors.New("Username not available")
	}

	if loginName == nil {
		return "", errors.New("No login operation or no session initalized")
	}

	return loginName.(string), nil
}

func buildOperation(username string, r *http.Request) (string, error) {
	buildBranch := r.PostFormValue("newbuildBranch")
	if buildBranch == "" {
		return "", errors.New("buildBranch is empty")
	}

	jenkinsURL, _ := url.ParseRequestURI("http://68.68.97.88:8080/job/Koding Deployment/buildWithParameters")
	q := jenkinsURL.Query()
	q.Set("token", "runBuildKoding")
	q.Set("BUILDBRANCH", buildBranch)
	q.Set("cause", fmt.Sprintf("by %s", username))
	jenkinsURL.RawQuery = q.Encode()

	_, err := http.Post(jenkinsURL.String(), "", nil)
	if err != nil {
		return "", err
	}

	msg := fmt.Sprintf("%s deployed a new build with branch '%s'", username, buildBranch)
	err = sendMsgToSlack("#_koding", msg)
	if err != nil {
		log.Error("slack error %v", err)
	}

	return buildBranch, nil
}

func switchOperation(loginName string, r *http.Request) (string, error) {
	version := r.PostFormValue("switchVersion")
	err := switchVersion(loginName, version)
	if err != nil {
		return "", err
	}

	return version, nil
}

func switchHost(host, newVersion string) error {
	log.Info("switch host %s to %s", host, newVersion)
	if host == "" {
		errors.New("host is not defined")
	}

	// Test if the string is an integer, if not abort
	_, err := strconv.Atoi(newVersion)
	if err != nil {
		return err
	}

	domain, err := modelhelper.GetDomain(host)
	if err != nil {
		return err
	}

	if domain.Proxy == nil {
		return fmt.Errorf("proxy field is empty for '%s'", host)
	}

	if domain.Proxy.Key == "" {
		return fmt.Errorf("key does not exist for '%s'", host)
	}

	domain.Proxy.Key = newVersion

	err = modelhelper.UpdateDomain(domain)
	if err != nil {
		log.Error("could not update %+v", domain)
		return err
	}

	log.Info("reset proxycache for host %s", host)
	resetURL := "http://koding-proxy0.sj.koding.com/_resetcache_/" + host
	resp, err := http.Get(resetURL)
	if err != nil {
		log.Error("COULD NOT SWITCH %v", err.Error())
	}

	if resp.StatusCode == 200 {
		log.Error("Cache is cleaned for %v", host)
	}

	return nil

}

func switchVersion(loginName, newVersion string) error {
	log.Info("switch is invoked by '%s' for build number '%s'\n", loginName, newVersion)
	err := switchHost(kodingHost, newVersion)
	if err != nil {
		return nil
	}

	err = switchHost(socialHost, newVersion)
	if err != nil {
		return nil
	}

	msg := fmt.Sprintf("%s switched <https://koding.com|koding.com> and <https://socialkoding.com|social.koding.com> to build %s",
		loginName, newVersion)
	err = sendMsgToSlack("#_koding", msg)
	if err != nil {
		log.Error("slack error %v", err)
	}

	return nil
}

func keyLookup(key string) (map[string]bool, map[string]bool) {
	workersApi := apiUrl + "/workers/?version=" + key
	servers := make(map[string]bool, 0)
	brokers := make(map[string]bool, 0)

	resp, err := http.Get(workersApi)
	if err != nil {
		log.Error("Error: %v", err)
		return nil, nil
	}

	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Error("Error: %v", err)
	}

	workers := make([]WorkerInfo, 0)
	err = json.Unmarshal(body, &workers)
	if err != nil {
		log.Error("Error: %v", err)
	}

	for _, w := range workers {
		if w.Name == "server" {
			servers[w.Hostname+":"+strconv.Itoa(w.Port)] = true
		}

		if w.Name == "broker" {
			brokers[w.Hostname+":"+strconv.Itoa(w.Port)] = true
		}

	}

	return servers, brokers
}

func jenkinsInfo() *JenkinsInfo {
	j := &JenkinsInfo{}
	jenkinsApi := "http://jenkins.sj.koding.com:8080/job/Koding%20Deployment/api/json"
	resp, err := http.Get(jenkinsApi)
	if err != nil {
		log.Error("Error: %v", err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Error("Error: %v", err)
	}

	err = json.Unmarshal(body, &j)
	if err != nil {
		log.Error("Error: %v", err)
	}

	return j
}

func workerInfo(build string) ([]WorkerInfo, StatusInfo, error) {
	s := StatusInfo{}
	workersApi := apiUrl + "/workers/?sort=state&version=" + build
	resp, err := http.Get(workersApi)
	if err != nil {
		return nil, s, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, s, err
	}

	workers := make([]WorkerInfo, 0)
	err = json.Unmarshal(body, &workers)
	if err != nil {
		return nil, s, err
	}

	s.BuildNumber = build

	for i, val := range workers {
		switch val.State {
		case "started":
			s.Workers.Started++
			workers[i].Info = "success"
			workers[i].State = "running"
		case "stopped":
			workers[i].Info = "warning"
		case "waiting":
			workers[i].Info = "info"
		case "dead":
			workers[i].Info = "error"
		}

		d, err := time.ParseDuration(strconv.Itoa(workers[i].Uptime) + "s")
		if err != nil {
			log.Error("Error: %v", err)
		}
		workers[i].Clock = d.String()
	}

	version, _ := currentVersion()
	s.CurrentVersion = version
	s.SwitchHost = kodingHost

	return workers, s, nil
}

func buildsInfo() []int {
	serverApi := apiUrl + "/deployments/"
	builds := make([]int, 0)

	resp, err := http.Get(serverApi)
	if err != nil {
		log.Error("Error: %v", err)
		return builds
	}
	defer resp.Body.Close()

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		log.Error("Error: %v", err)
	}

	s := &[]ServerInfo{}
	err = json.Unmarshal(body, &s)
	if err != nil {
		log.Error("Error: %v", err)
	}

	for _, serv := range *s {
		build, _ := strconv.Atoi(serv.BuildNumber)
		builds = append(builds, build)
	}
	sort.Sort(sort.Reverse(sort.IntSlice(builds)))

	return builds
}

func serverInfo(build string) (*ServerInfo, error) {
	serverApi := apiUrl + "/deployments/" + build

	resp, err := http.Get(serverApi)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	s := &ServerInfo{}
	err = json.Unmarshal(body, &s)
	if err != nil {
		return nil, err
	}

	if s.BuildNumber == "" {
		return s, fmt.Errorf("there is no deployment for build number %s\n", build)
	}

	s.MongoLogin = parseMongoLogin(s.Config.Mongo)

	return s, nil
}

func parseMongoLogin(login string) string {
	u, err := url.Parse("http://" + login)
	if err != nil {
		log.Error("Error: %v", err)
	}

	mPass, _ := u.User.Password()
	return fmt.Sprintf(
		"mongo %s%s -u%s -p%s",
		u.Host,
		u.Path,
		u.User.Username(),
		mPass,
	)
}

func domainInfo() (Domain, error) {
	d := Domain{}
	domainApi := apiUrl + "/domains/" + kodingHost

	resp, err := http.Get(domainApi)
	if err != nil {
		return d, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return d, err
	}

	err = json.Unmarshal(body, &d)
	if err != nil {
		fmt.Printf("Couldn't unmarshall '%s' into a domain object.\n", kodingHost)
		return d, err
	}

	return d, nil
}

func currentVersion() (string, error) {
	if kodingHost == "" {
		errors.New("kodingHost is not defined")
	}

	domain, err := modelhelper.GetDomain(kodingHost)
	if err != nil {
		return "", err
	}

	if domain.Proxy == nil {
		return "", fmt.Errorf("proxy field is empty for '%s'", kodingHost)
	}

	currentVersion := domain.Proxy.Key
	if currentVersion == "" {
		return "", fmt.Errorf("key does not exist for '%s'", kodingHost)
	}

	return currentVersion, nil
}

func authenticateUser(username, password string) error {
	user, err := modelhelper.CheckAndGetUser(username, password)
	if err != nil {
		return errors.New("Wrong username or password")
	}

	account, err := modelhelper.GetAccount(user.Name)
	if err != nil {
		return fmt.Errorf("Could not retrieve account '%s'.", user.Name)
	}

	for _, flag := range account.GlobalFlags {
		if flag == "super-admin" {
			return nil
		}
	}

	return errors.New("You don't have super-admin flag")
}

func renderTemplate(w http.ResponseWriter, tmpl string, data interface{}) {
	err := templates.ExecuteTemplate(w, tmpl+".html", data)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

type slackPayload struct {
	Channel   string `json:"channel"`
	Username  string `json:"username"`
	Text      string `json:"text"`
	IconEmoji string `json:"icon_emoji"`
}

func sendMsgToSlack(channel, text string) error {
	hookURL := "https://koding.slack.com/services/hooks/incoming-webhook?token=z7TCJnrGy3kpcRLkbBbUzlKh"

	payload := slackPayload{
		Channel:   channel,
		Username:  "Koding Overview",
		Text:      text,
		IconEmoji: ":rocket:",
	}

	data, err := json.Marshal(&payload)
	if err != nil {
		return err
	}

	resp, err := http.Post(hookURL, "application/json", bytes.NewReader(data))
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return nil
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}

	return fmt.Errorf("slack err: %s", string(body))
}
