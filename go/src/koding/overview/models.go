package main

import (
	"time"

	"labix.org/v2/mgo/bson"
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
