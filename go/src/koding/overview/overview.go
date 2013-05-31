package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
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
	Username string
	Name     string
	Key      string
	FullUrl  string
}

type DomainInfo struct {
	Domains map[string]Domain `json:"domains"`
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
	BuildNumber string
	NewKoding   struct {
		ServerHost string
		BrokerHost string
	}
	Workers struct {
		Running int
		Dead    int
	}
}

type HomePage struct {
	Status  StatusInfo
	Workers []WorkerInfo
	Jenkins *JenkinsInfo
	Server  *ServerInfo
	Builds  []int
	Domains map[string]Domain
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

const uptimeLayout = "03:04:00"

func main() {
	http.HandleFunc("/", viewHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir("bootstrap/"))))

	fmt.Println("koding overview started")
	err := http.ListenAndServe(":8080", nil)
	if err != nil {
		fmt.Println(err)
	}
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	build := r.FormValue("build")
	if build == "" {
		build = "latest"
	}

	workers, status, err := workerInfo(build)
	if err != nil {
		fmt.Println(err)
	}

	jenkins := jenkinsInfo()
	builds := buildsInfo()

	domains, err := domainInfo()
	if err != nil {
		fmt.Println(err)
		domains = &DomainInfo{}
	}

	server, err := serverInfo(build)
	if err != nil {
		fmt.Println(err)
		server = NewServerInfo()
	}

	s, b := keyLookup(domains.Domains["new.koding.com"])
	status.NewKoding.ServerHost = s
	status.NewKoding.BrokerHost = b

	home := HomePage{
		Status:  status,
		Workers: workers,
		Jenkins: jenkins,
		Server:  server,
		Builds:  builds,
		Domains: domains.Domains,
	}

	renderTemplate(w, "index", home)
	return
}

func keyLookup(domain Domain) (string, string) {
	workersApi := "http://kontrol.in.koding.com/workers?version=" + domain.Key
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

	var server string
	var broker string
	for _, w := range workers {
		if w.Name == "server" {
			server = w.Hostname + ":" + strconv.Itoa(w.Port)
		}

		if w.Name == "broker" {
			broker = w.Hostname + ":" + strconv.Itoa(w.Port)
		}

	}

	return server, broker
}

func renderTemplate(w http.ResponseWriter, tmpl string, home HomePage) {
	err := templates.ExecuteTemplate(w, tmpl+".html", home)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func jenkinsInfo() *JenkinsInfo {
	fmt.Println("getting jenkins info")
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
		case "running":
			s.Workers.Running++
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

func domainInfo() (*DomainInfo, error) {
	domainApi := "http://kontrol.in.koding.com/proxies/proxy.in.koding.com/domains"
	resp, err := http.Get(domainApi)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	d := &DomainInfo{}
	err = json.Unmarshal(body, &d)
	if err != nil {
		return nil, err
	}

	return d, nil
}
