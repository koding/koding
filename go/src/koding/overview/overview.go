package main

import (
	"crypto/sha1"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/fatih/goset"
	"github.com/gorilla/sessions"
	"github.com/streadway/amqp"
	"html/template"
	"io"
	"io/ioutil"
	"koding/databases/mongo"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"net/http"
	"net/url"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"
)

type ConfigFile struct {
	Mongo string
	Mq    struct {
		Host          string
		Port          int
		ComponentUser string
		Password      string
		Vhost         string
	}
}

type Domain struct {
	Domainname string `json:"Domain"`
	Proxy      struct {
		Mode        string `json:"mode"`
		Username    string `json:"username"`
		Servicename string `json:"servicename"`
		Key         string `json:"key"`
	} `json:"Proxy"`
	FullUrl string `json:"Domain"`
}

type ServerInfo struct {
	BuildNumber string
	GitBranch   string
	GitCommit   string
	ConfigUsed  string
	Config      ConfigFile
	Hostname    Hostname
	IP          IP
	MongoLogin  string
}

type Hostname struct {
	Public string
	Local  string
}

type IP struct {
	Public string
	Local  string
}

type JenkinsInfo struct {
	LastCompletedBuild struct {
		Number int    `json:"number"`
		Url    string `json:"url"`
	} `json:"lastCompletedBuild"`
	LastStableBuild struct {
		Number int    `json:"number"`
		Url    string `json:"url"`
	} `json:"lastStableBuild"`
	LastFailedBuild struct {
		Number int    `json:"number"`
		Url    string `json:"url"`
	} `json:"lastFailedBuild"`
}

type WorkerInfo struct {
	Name      string    `json:"name"`
	Uuid      string    `json:"uuid"`
	Hostname  string    `json:"hostname"`
	Version   int       `json:"version"`
	Timestamp time.Time `json:"timestamp"`
	Pid       int       `json:"pid"`
	State     string    `json:"state"`
	Info      string    `json:"info"`
	Clock     string    `json:"clock"`
	Uptime    int       `json:"uptime"`
	Port      int       `json:"port"`
}

type StatusInfo struct {
	BuildNumber    string
	CurrentVersion string
	SwitchHost     string
	Koding         struct {
		ServerLen   int
		ServerHosts map[string]bool
		BrokerLen   int
		BrokerHosts map[string]bool
	}
	Workers struct {
		Started int
	}
}

type HomePage struct {
	Status        StatusInfo
	Workers       []WorkerInfo
	Jenkins       *JenkinsInfo
	Server        *ServerInfo
	Builds        []int
	LoginName     string
	SwitchMessage string
	LoginMessage  string
}

type User struct {
	Id            bson.ObjectId `bson:"_id" json:"-"`
	Email         string        `bson:"email" json:"email"`
	LastLoginDate time.Time     `bson:"lastLoginDate" json:"lastLoginDate"`
	Password      string        `bson:"password" json:"password"`
	RegisteredAt  time.Time     `bson:"registeredAt" json:"registeredAt"`
	Salt          string        `bson:"salt" json:"salt"`
	Status        string        `bson:"status" json:"status"`
	Uid           int           `bson:"uid" json:"uid"`
	Username      string        `bson:"username" json:"username"`
}

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
	switchHost string
	apiUrl     = "http://kontrol.in.koding.com:80" // default
	proxyDB    *proxyconfig.ProxyConfiguration
	templates  = template.Must(template.ParseFiles(
		"templates/index.html",
		"templates/login.html",
	))
)

const uptimeLayout = "03:04:00"

var store = sessions.NewCookieStore([]byte("user"))

func main() {
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		res := fmt.Sprintf("proxyconfig mongodb connect: %s", err)
		log.Println(res)
	}

	// used for kontrolapi
	apiHost := config.Current.Kontrold.Overview.ApiHost
	apiPort := config.Current.Kontrold.Overview.ApiPort
	apiUrl = "http://" + apiHost + ":" + strconv.Itoa(apiPort)

	// used to create the listener
	port := config.Current.Kontrold.Overview.Port

	// domain to be switched, like 'koding.com'
	switchHost = config.Current.Kontrold.Overview.SwitchHost

	http.HandleFunc("/", viewHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir("bootstrap/"))))

	fmt.Println("koding overview started")
	err = http.ListenAndServe(":"+strconv.Itoa(port), nil)
	if err != nil {
		fmt.Println(err)
	}
}

func logAction(msg string) {
	fileName := "versionswitchers.log"
	flag := os.O_WRONLY | os.O_CREATE | os.O_APPEND
	mode := os.FileMode(0644)

	f, err := os.OpenFile(fileName, flag, mode)
	if err != nil {
		log.Println("error opening version switch log file")
		return
	}
	defer f.Close()

	f.WriteString(fmt.Sprintf("[%s] %s\n", time.Now().Format(time.RFC1123), msg))
}

func checkSessionOrDoLogin(w http.ResponseWriter, r *http.Request) (string, string) {
	operation := r.PostFormValue("operation")
	if operation == "login" {
		loginName := r.PostFormValue("loginName")
		loginPass := r.PostFormValue("loginPass")
		if loginName == "" || loginPass == "" {
			return "", "Please enter a username and password"
		}
		// abort if password and username is not valid
		success, err, loginMessage := checkUserLogin(loginName, loginPass)
		if !success {
			if err != nil {
				log.Println(err)
				return "", loginMessage
			} else {
				return "", loginMessage
			}
		}
		session, err := store.Get(r, "userData")
		if err != nil {
			log.Println("Session could not be retrieved")
			return "", "An internal problem occured"
		}
		session.Values["userName"] = loginName
		store.Save(r, w, session)
		return loginName, ""
	}

	session, err := store.Get(r, "userData")
	if err != nil {
		log.Println("Session could not be retrieved")
		return "", "An internal problem occured"
	}
	loginName, ok := session.Values["userName"]
	if ok == true {
		if loginName == nil {
			// no login operation or no session initialized
			return "", ""
		}
		s := loginName.(string)
		return s, ""
	}
	return "", "An internal problem occured"
}

func logOut(w http.ResponseWriter, r *http.Request) error {
	session, err := store.Get(r, "userData")
	if err == nil {
		session.Values["userName"] = nil
		store.Save(r, w, session)
		return nil
	} else {
		return errors.New("Session could not be retrieved")
	}
}

func checkUserLogin(username string, password string) (bool, error, string) {
	admins := goset.New("devrim", "fatih", "geraint", "huseyinalb")
	user := User{}
	query := func(c *mgo.Collection) error {
		err := c.Find(bson.M{"username": username}).One(&user)
		return err
	}
	mgoerror := mongo.SearchCollection("koding", "jUsers", query)
	if mgoerror != nil {
		log.Println(mgoerror)
		return false, nil, "Username not found"
	}

	iostring := sha1.New()
	io.WriteString(iostring, user.Salt)
	io.WriteString(iostring, password)

	sha1pass := fmt.Sprintf("%x", iostring.Sum(nil))
	if user.Password == sha1pass && admins.Has(user.Username) {
		return true, nil, ""
	} else {
		return false, nil, "Password is incorrect"
	}

}

func viewHandler(w http.ResponseWriter, r *http.Request) {

	// Should be done first
	operation := r.FormValue("operation")
	if operation == "logout" {
		err := logOut(w, r)
		if err != nil {
			log.Println(err)
		}
	}

	loginName, loginMessage := checkSessionOrDoLogin(w, r)

	if loginName == "" {
		home := HomePage{
			LoginMessage: loginMessage,
		}
		renderTemplate(w, "login", home)
		return
	}

	build := r.FormValue("build")
	if build == "" || build == "current" {
		version, _ := currentVersion()
		build = version
	}

	switchMessage := ""
	if operation == "switchVersion" {
		version := r.PostFormValue("switchVersion")
		loginPass := r.PostFormValue("loginPass")
		success, err, loginMessage := checkUserLogin(loginName, loginPass)
		if success {
			log.Println("switching to version", version)
			err := switchVersion(version)
			if err != nil {
				switchMessage = fmt.Sprintf("Error switching, err: %s version: %s", err, version)
				log.Println("error switching", err, version)
			} else {
				switchMessage = "Switched to version " + loginName
				logAction(fmt.Sprintf("Switched to version %s switcher name: %s", version, loginName))
			}
		} else {
			if err != nil {
				log.Println(err)
			}
			switchMessage = loginMessage
		}
	}

	workers, status, err := workerInfo(build)
	if err != nil {
		fmt.Println(err)
	}

	jenkins := jenkinsInfo()
	builds := buildsInfo()

	server, err := serverInfo(build)
	if err != nil {
		fmt.Println(err)
		server = NewServerInfo()
	}

	domain, err := domainInfo()
	if err != nil {
		fmt.Println(err)
	}

	s, b := keyLookup(domain.Proxy.Key)
	status.Koding.ServerHosts = s
	status.Koding.ServerLen = len(s) + 1
	status.Koding.BrokerHosts = b
	status.Koding.BrokerLen = len(b) + 1

	home := HomePage{
		Status:        status,
		Workers:       workers,
		Jenkins:       jenkins,
		Server:        server,
		Builds:        builds,
		LoginName:     loginName,
		SwitchMessage: switchMessage,
	}

	renderTemplate(w, "index", home)
	return
}

func keyLookup(key string) (map[string]bool, map[string]bool) {
	workersApi := apiUrl + "/workers?version=" + key
	resp, err := http.Get(workersApi)
	if err != nil {
		fmt.Println(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	workers := make([]WorkerInfo, 0)
	err = json.Unmarshal(body, &workers)
	if err != nil {
		fmt.Println(err)
	}

	servers := make(map[string]bool, 0)
	brokers := make(map[string]bool, 0)
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

func renderTemplate(w http.ResponseWriter, tmpl string, home interface{}) {
	err := templates.ExecuteTemplate(w, tmpl+".html", home)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func jenkinsInfo() *JenkinsInfo {
	j := &JenkinsInfo{}
	jenkinsApi := "http://salt-master.in.koding.com/job/build-koding/api/json"
	resp, err := http.Get(jenkinsApi)
	if err != nil {
		fmt.Println(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	err = json.Unmarshal(body, &j)
	if err != nil {
		fmt.Println(err)
	}

	return j
}

func workerInfo(build string) ([]WorkerInfo, StatusInfo, error) {
	s := StatusInfo{}
	workersApi := apiUrl + "/workers?version=" + build
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
		}

		d, err := time.ParseDuration(strconv.Itoa(workers[i].Uptime) + "s")
		if err != nil {
			fmt.Println(err)
		}
		workers[i].Clock = d.String()
	}

	version, _ := currentVersion()
	s.CurrentVersion = version
	s.SwitchHost = switchHost

	return workers, s, nil
}

func buildsInfo() []int {
	serverApi := apiUrl + "/deployments"
	fmt.Println(serverApi)
	resp, err := http.Get(serverApi)
	if err != nil {
		fmt.Println(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	s := &[]ServerInfo{}
	err = json.Unmarshal(body, &s)
	if err != nil {
		fmt.Println(err)
	}

	builds := make([]int, 0)
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

	s.MongoLogin = parseMongoLogin(s.Config.Mongo)

	return s, nil
}

func parseMongoLogin(login string) string {
	u, err := url.Parse("http://" + login)
	if err != nil {
		fmt.Println(err)
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
	domainApi := apiUrl + "/domains/" + switchHost

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
		fmt.Printf("Couldn't unmarshall '%s' into a domain object.\n", switchHost)
		return d, err
	}

	return d, nil
}

func currentVersion() (string, error) {
	if switchHost == "" {
		errors.New("switchHost is not defined")
	}

	domain, err := proxyDB.GetDomain(switchHost)
	if err != nil {
		return "", err
	}

	if domain.Proxy == nil {
		return "", fmt.Errorf("proxy field is empty for '%s'", switchHost)
	}

	currentVersion := domain.Proxy.Key
	if currentVersion == "" {
		return "", fmt.Errorf("key does not exist for '%s'", switchHost)
	}

	return currentVersion, nil
}

func switchVersion(newVersion string) error {
	if switchHost == "" {
		errors.New("switchHost is not defined")
	}

	// Test if the string is an integer, if not abort
	_, err := strconv.Atoi(newVersion)
	if err != nil {
		return err
	}

	domain, err := proxyDB.GetDomain(switchHost)
	if err != nil {
		return err
	}

	if domain.Proxy == nil {
		return fmt.Errorf("proxy field is empty for '%s'", switchHost)
	}

	if domain.Proxy.Key == "" {
		return fmt.Errorf("key does not exist for '%s'", switchHost)
	}

	domain.Proxy.Key = newVersion

	err = proxyDB.UpdateDomain(&domain)
	if err != nil {
		log.Printf("could not update %+v\n", domain)
		return err
	}

	return nil
}

func CreateAmqpConnection(component string) *amqp.Connection {
	conn, err := amqp.Dial(amqp.URI{
		Scheme:   "amqp",
		Host:     config.Current.Mq.Host,
		Port:     config.Current.Mq.Port,
		Username: strings.Replace(config.Current.Mq.ComponentUser, "<component>", component, 1),
		Password: config.Current.Mq.Password,
		Vhost:    config.Current.Mq.Vhost,
	}.String())
	if err != nil {
		log.Fatalln("AMQP dial: ", err)
	}

	return conn
}

func CreateChannel(conn *amqp.Connection) *amqp.Channel {
	channel, err := conn.Channel()
	if err != nil {
		log.Fatalln("AMQP create channel: ", err)
	}
	return channel
}
