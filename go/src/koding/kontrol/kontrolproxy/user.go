package main

import (
	"fmt"
	"koding/tools/db"
	"koding/virt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"math"
	"net"
	"net/http"
	"net/url"
	"strings"
)

type UserInfo struct {
	Username    string
	Servicename string
	Key         string
	FullUrl     string
	DomainMode  string
	Host        string
	IP          string
	Country     string
	Target      *url.URL
	Redirect    bool
}

func NewUserInfo(username, servicename, key, fullurl, mode, host string) *UserInfo {
	return &UserInfo{
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
		DomainMode:  mode,
		Host:        host,
	}
}

func populateUser(outreq *http.Request) (*UserInfo, error) {
	user, err := parseDomain(outreq.Host)
	if err != nil {
		return nil, err
	}

	host, err := user.populateIP(outreq.RemoteAddr)
	if err != nil {
		fmt.Println(err)
	} else {
		user.populateCountry(host)
	}

	err = user.populateTarget()
	if err != nil {
		return nil, err
	}

	fmt.Printf("--\nconnected user information %v\n", user)
	return user, nil
}

func (u *UserInfo) populateIP(remoteAddr string) (string, error) {
	host, _, err := net.SplitHostPort(remoteAddr)
	if err != nil {
		fmt.Printf("could not split host and port: %s", err.Error())
		return "", err
	}
	u.IP = host
	return host, nil
}

func (u *UserInfo) populateCountry(host string) {
	if geoIP != nil {
		loc := geoIP.GetLocationByIP(host)
		if loc != nil {
			u.Country = loc.CountryName
		}
	}
}

func (u *UserInfo) populateTarget() error {
	var err error
	username := u.Username
	servicename := u.Servicename
	key := u.Key

	switch u.DomainMode {
	case "direct":
		u.Target, err = url.Parse("http://" + u.FullUrl)
		if err != nil {
			return err
		}
		return nil
	case "vm":
		var vm virt.VM
		fmt.Println("got vm ip from mongodb")
		if err := db.VMs.Find(bson.M{"hostname": u.Host}).One(&vm); err != nil {
			u.Target, _ = url.Parse("http://www.koding.com/notfound.html")
			u.Redirect = true
			return nil
		}
		if vm.IP == nil {
			u.Target, _ = url.Parse("http://www.koding.com/notactive.html")
			u.Redirect = true
			return nil
		}
		u.Target, err = url.Parse("http://" + vm.IP.String())
		if err != nil {
			return err
		}

		return nil
	case "internal":
		break // internal is done below
	}

	keyData, err := proxyDB.GetKey(username, servicename, key)
	if err != nil {
		return fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'", username, servicename, key)
	}

	var hostname string
	switch keyData.Mode {
	case "roundrobin":
		N := float64(len(keyData.Host))
		n := int(math.Mod(float64(keyData.CurrentIndex+1), N))
		hostname = keyData.Host[n]

		keyData.CurrentIndex = n
		go proxyDB.UpdateKeyData(username, servicename, keyData)
	case "sticky":
		hostname = keyData.Host[keyData.CurrentIndex]
	}

	u.Target, err = url.Parse("http://" + hostname)
	if err != nil {
		return err
	}

	u.Redirect = false

	return nil
}

func parseDomain(host string) (*UserInfo, error) {
	// first try to get from domain collection
	domain, err := proxyDB.GetDomain(host)
	if err == nil { // because we don't want have nested if clauses
		return NewUserInfo(domain.Username, domain.Servicename, domain.Key, domain.FullUrl, domain.Mode, host), nil
	}

	if err != mgo.ErrNotFound {
		return &UserInfo{}, fmt.Errorf("no domain lookup keys found for host '%s'", host)
	}

	switch counts := strings.Count(host, "-"); {
	case counts == 0:
		if strings.HasSuffix(host, "kd.io") {
			return NewUserInfo("", "", "", "", "vm", host), nil
		}

	case counts == 1:
		// host is in form {name}-{key}.kd.io, used by koding
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.Split(firstSub, "-")
		servicename := partsSecond[0]
		key := partsSecond[1]

		return NewUserInfo("koding", servicename, key, "", "internal", host), nil
	case counts > 1:
		// host is in form {name}-{key}-{username}.kd.io, used by users
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.SplitN(firstSub, "-", 3)
		servicename := partsSecond[0]
		key := partsSecond[1]
		username := partsSecond[2]

		return NewUserInfo(username, servicename, key, "", "internal", host), nil
	}
	return &UserInfo{}, fmt.Errorf("no data available for proxy. can't parse domain %s", host)
}

func validate(u *UserInfo) (bool, error) {
	res, err := proxyDB.GetRule(u.Host)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	return validator(res, u).IP().Country().Check()
}

// func lookupRabbitKey(username, servicename, key string) (string, error) {
// 	res, err := proxyDB.GetKey(username, servicename, key)
// 	if err != nil {
// 		return "", fmt.Errorf("no rabbitkey available for user '%s'\n", username)
// 	}
//
// 	if res.Mode == "roundrobin" {
// 		return "", fmt.Errorf("round-robin is disabled for user %s\n", username)
// 	}
//
// 	if res.RabbitKey == "" {
// 		return "", fmt.Errorf("rabbitkey is empty for user %s\n", username)
// 	}
//
// 	return res.RabbitKey, nil
// }

func checkWebsocket(req *http.Request) bool {
	conn_hdr := ""
	conn_hdrs := req.Header["Connection"]
	if len(conn_hdrs) > 0 {
		conn_hdr = conn_hdrs[0]
	}

	upgrade_websocket := false
	if strings.ToLower(conn_hdr) == "upgrade" {
		upgrade_hdrs := req.Header["Upgrade"]
		if len(upgrade_hdrs) > 0 {
			upgrade_websocket = (strings.ToLower(upgrade_hdrs[0]) == "websocket")
		}
	}

	return upgrade_websocket
}

func logDomainStat(name string) {
	if name == "" {
		return
	}

	err := proxyDB.AddDomainStat(name)
	if err != nil {
		fmt.Printf("could not add domain statistisitcs for %s\n", err.Error())
	}
}

func logProxyStat(name, country string) {
	err := proxyDB.AddProxyStat(name, country)
	if err != nil {
		fmt.Printf("could not add proxy statistisitcs for %s\n", err.Error())
	}
}
