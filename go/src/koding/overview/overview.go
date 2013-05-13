package main

import (
	"encoding/json"
	"fmt"
	"html/template"
	"io/ioutil"
	"net/http"
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

type ServerInfo struct {
	BuildNumber string
	GitBranch   string
	ConfigUsed  string
	Config      ConfigFile
	Hostname    Hostname
	IP          IP
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
	Uptime    int       `json:"uptime"`
	Port      int       `json:"port"`
}

type StatusInfo struct {
	BuildNumber string
	Workers     struct {
		Running int
		Dead    int
	}
}

type HomePage struct {
	Status  StatusInfo
	Workers []WorkerInfo
	Jenkins *JenkinsInfo
	Server  *ServerInfo
}

var templates = template.Must(template.ParseFiles("index.html"))

func main() {
	http.HandleFunc("/", viewHandler)
	http.Handle("/bootstrap/", http.StripPrefix("/bootstrap/", http.FileServer(http.Dir("bootstrap/"))))

	fmt.Println("koding overview started")
	http.ListenAndServe(":8080", nil)
}

func viewHandler(w http.ResponseWriter, r *http.Request) {
	workers := workerInfo()
	status := statusInfo()
	jenkins := jenkinsInfo()
	server := serverInfo()

	for i, val := range workers {
		switch val.State {
		case "running":
			status.Workers.Running++
			workers[i].Info = "success"
		case "dead":
			status.Workers.Dead++
			workers[i].Info = "error"
		case "stopped":
			workers[i].Info = "warning"
		case "waiting":
			workers[i].Info = "info"
		}
	}

	home := HomePage{
		Status:  status,
		Workers: workers,
		Jenkins: jenkins,
		Server:  server,
	}

	renderTemplate(w, "index", home)
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

func statusInfo() StatusInfo {
	s := StatusInfo{}
	return s
}

func workerInfo() []WorkerInfo {
	workersApi := "http://api.x.koding.com/workers?version=latest"
	resp, err := http.Get(workersApi)
	if err != nil {
		fmt.Println(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	w := make([]WorkerInfo, 0)
	err = json.Unmarshal(body, &w)
	if err != nil {
		fmt.Println(err)
	}

	return w
}

func serverInfo() *ServerInfo {
	serverApi := "http://api.x.koding.com/deployments"

	resp, err := http.Get(serverApi)
	if err != nil {
		fmt.Println(err)
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Println(err)
	}

	s := &ServerInfo{}
	err = json.Unmarshal(body, &s)
	if err != nil {
		fmt.Println(err)
	}

	return s
}
