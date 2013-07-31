package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"html/template"
	"io/ioutil"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/tools/amqputil"
	"log"
	"net/http"
	"net/url"
	"sort"
	"strconv"
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
	Koding         struct {
		ServerHosts []string
		BrokerHosts []string
	}
	Workers struct {
		Started int
		Dead    int
	}
}

type HomePage struct {
	Status  StatusInfo
	Workers []WorkerInfo
	Jenkins *JenkinsInfo
	Server  *ServerInfo
	Builds  []int
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

var templates = template.Must(template.ParseFiles("index.html"))
var proxyDB *proxyconfig.ProxyConfiguration

const uptimeLayout = "03:04:00"

func main() {
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		res := fmt.Sprintf("proxyconfig mongodb connect: %s", err)
		log.Println(res)
	}

	http.HandleFunc("/", viewHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir("bootstrap/"))))

	fmt.Println("koding overview started")
	err = http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println(err)
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	build := r.FormValue("build")
	if build == "" || build == "current" {
		version, _ := currentVersion()
		build = version
	}

	version := r.PostFormValue("switchVersion")
	if version != "" {
		log.Println("switching to version", version)
		err := switchVersion(version)
		if err != nil {
			log.Println("error switching", err, version)
		}
		http.Redirect(w, r, "/", http.StatusFound)
		return
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
	status.Koding.BrokerHosts = b

	home := HomePage{
		Status:  status,
		Workers: workers,
		Jenkins: jenkins,
		Server:  server,
		Builds:  builds,
	}

	renderTemplate(w, "index", home)
	return
}

func keyLookup(key string) ([]string, []string) {
	workersApi := "http://kontrol.in.koding.com/workers?version=" + key
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

	servers := make([]string, 0)
	brokers := make([]string, 0)
	for _, w := range workers {
		if w.Name == "server" {
			servers = append(servers, w.Hostname+":"+strconv.Itoa(w.Port))
		}

		if w.Name == "broker" {
			brokers = append(brokers, w.Hostname+":"+strconv.Itoa(w.Port))
		}

	}

	return servers, brokers
}

func renderTemplate(w http.ResponseWriter, tmpl string, home HomePage) {
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

	workersApi := "http://kontrol.in.koding.com/workers?version=" + build
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
		case "dead":
			s.Workers.Dead++
			workers[i].Info = "error"
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

	return workers, s, nil
}

func buildsInfo() []int {
	serverApi := "http://kontrol.in.koding.com/deployments"
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
	serverApi := "http://kontrol.in.koding.com/deployments/" + build

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
	domainApi := "http://kontrol.in.koding.com/domains/koding.com"
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
		fmt.Println("Couldn't unmarshall koding.com into a domain object.")
		return d, err
	}

	return d, nil
}

func currentVersion() (string, error) {
	domain, err := proxyDB.GetDomain("koding.com") // will be changed to koding.com
	if err != nil {
		return "", err
	}

	if domain.Proxy == nil {
		return "", errors.New("proxy field is empty for koding.com")
	}

	currentVersion := domain.Proxy.Key
	if currentVersion == "" {
		return "", errors.New("key does not exist for koding.com")
	}

	return currentVersion, nil
}

func switchVersion(newVersion string) error {
	// Test if the string is an integer, if not abort
	_, err := strconv.Atoi(newVersion)
	if err != nil {
		return err
	}

	domain, err := proxyDB.GetDomain("koding.com")
	if err != nil {
		return err
	}

	if domain.Proxy == nil {
		return errors.New("proxy field is empty for koding.com")
	}

	oldVersion := domain.Proxy.Key
	if oldVersion == "" {
		return errors.New("key does not exist for koding.com")
	}

	conn := amqputil.CreateConnection("overview")
	defer conn.Close()

	channel := amqputil.CreateChannel(conn)
	defer channel.Close()

	destination := "auth-" + newVersion
	routingKey := ""
	source := "auth"

	err = channel.ExchangeBind(destination, routingKey, source, true, nil)
	if err != nil {
		return err
	}

	oldDestination := "auth-" + oldVersion

	err = channel.ExchangeUnbind(oldDestination, routingKey, source, true, nil)
	if err != nil {
		return err
	}

	domain.Proxy.Key = newVersion

	err = proxyDB.UpdateDomain(&domain)
	if err != nil {
		log.Printf("could not update %+v\n", domain)
		return err
	}

	return nil
}
