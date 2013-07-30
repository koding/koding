package clientconfig

import (
	"koding/tools/config"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"log"
	"time"
)

type ServerInfo struct {
	BuildNumber string
	GitBranch   string
	GitCommit   string
	ConfigUsed  string
	Config      *ConfigFile
	Hostname    Hostname
	IP          IP
	CreatedAt   time.Time
}

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

type Hostname struct {
	Public string
	Local  string
}

type IP struct {
	Public string
	Local  string
}

type ClientConfig struct {
	Hostname        string
	RegisteredHosts map[string][]string
	Session         *mgo.Session
	Collection      *mgo.Collection
}

func Connect() (*ClientConfig, error) {
	session, err := mgo.Dial(config.Current.Mongo)
	if err != nil {
		return nil, err
	}
	session.SetMode(mgo.Strong, true)
	session.SetSafe(&mgo.Safe{})
	database := session.DB("")

	col := database.C("jKontrolClients")

	cc := &ClientConfig{
		Session:    session,
		Collection: col,
	}

	return cc, nil
}

func (c *ClientConfig) AddClient(info ServerInfo) {
	info.CreatedAt = time.Now()
	_, err := c.Collection.Upsert(bson.M{"buildnumber": info.BuildNumber}, info)
	if err != nil {
		log.Println(err)
	}

}

func (c *ClientConfig) GetClients() []ServerInfo {
	info := ServerInfo{}
	infos := make([]ServerInfo, 0)
	iter := c.Collection.Find(nil).Iter()
	for iter.Next(&info) {
		infos = append(infos, info)
	}

	return infos
}

func (c *ClientConfig) DeleteClient(build string) error {
	err := c.Collection.Remove(bson.M{"buildnumber": build})
	if err != nil {
		return err
	}
	return nil
}
