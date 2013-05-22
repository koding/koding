package main

import (
	"errors"
	"fmt"
	"koding/tools/db"
	"koding/virt"
	"labix.org/v2/mgo/bson"
	"net"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
)

type UserInfo struct {
	Username    string
	Servicename string
	Key         string
	FullUrl     string
	DomainMode  string
	IP          string
	Country     string
}

func NewUserInfo(username, servicename, key, fullurl, mode string) *UserInfo {
	return &UserInfo{
		Username:    username,
		Servicename: servicename,
		Key:         key,
		FullUrl:     fullurl,
		DomainMode:  mode,
	}
}

func populateUser(outreq *http.Request) (*UserInfo, error) {
	userInfo := &UserInfo{}
	host, _, err := net.SplitHostPort(outreq.RemoteAddr)
	if err != nil {
		fmt.Printf("could not split host and port: %s", err.Error())
	} else {
		userInfo.IP = host
	}

	if geoIP != nil {
		loc := geoIP.GetLocationByIP(host)
		if loc != nil {
			userInfo.Country = loc.CountryName
		}
	}

	userInfo, err = parseDomain(outreq.Host)
	if err != nil {
		return userInfo, err
	}

	return userInfo, nil
}

func parseDomain(host string) (*UserInfo, error) {
	switch counts := strings.Count(host, "-"); {
	case counts == 0:
		// otherwise lookup to our list of domains
		userInfo, err := lookupDomain(host)
		if err != nil {
			return nil, err
		}

		return userInfo, nil

	case counts == 1:
		// host is in form {name}-{key}.kd.io, used by koding
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.Split(firstSub, "-")
		servicename := partsSecond[0]
		key := partsSecond[1]

		return NewUserInfo("koding", servicename, key, "", "internal"), nil
	case counts > 1:
		// host is in form {name}-{key}-{username}.kd.io, used by users
		partsFirst := strings.Split(host, ".")
		firstSub := partsFirst[0]

		partsSecond := strings.SplitN(firstSub, "-", 3)
		servicename := partsSecond[0]
		key := partsSecond[1]
		username := partsSecond[2]

		return NewUserInfo(username, servicename, key, "", "internal"), nil
	default:
		return &UserInfo{}, errors.New("no data available for proxy")
	}

}

func lookupDomain(domainname string) (*UserInfo, error) {
	d := strings.SplitN(domainname, ".", 2)[1]
	if d == "kd.io" {
		vmName := strings.SplitN(domainname, ".", 2)[0]
		return NewUserInfo(vmName, "", "", "", "vm"), nil
	}

	domain, ok := proxy.DomainRoutingTable.Domains[domainname]
	if !ok {
		return &UserInfo{}, fmt.Errorf("no domain lookup keys found for host '%s'", domainname)
	}

	return NewUserInfo(domain.Username, domain.Name, domain.Key, domain.FullUrl, domain.Mode), nil
}

func lookupRabbitKey(username, servicename, key string) string {
	var rabbitkey string

	_, ok := proxy.RoutingTable[username]
	if !ok {
		fmt.Println("no user available in the db. rabbitkey not found")
		return rabbitkey
	}
	user := proxy.RoutingTable[username]

	keyRoutingTable := user.Services[servicename]
	keyDataList := keyRoutingTable.Keys[key]

	for _, keyData := range keyDataList {
		rabbitkey = keyData.RabbitKey
	}

	return rabbitkey //returns empty if not found
}

func targetHost(user *UserInfo) (*url.URL, error) {
	var hostname string

	username := user.Username
	servicename := user.Servicename
	key := user.Key

	switch user.DomainMode {
	case "direct":
		target, err := url.Parse("http://" + user.FullUrl)
		if err != nil {
			return nil, err
		}
		return target, nil
	case "vm":
		var vm virt.VM
		if err := db.VMs.Find(bson.M{"name": username}).One(&vm); err != nil {
			target, _ := url.Parse("http://www.koding.com/notfound.html")
			return target, errors.New("redirect")
		}
		if vm.IP == nil {
			target, _ := url.Parse("http://www.koding.com/notactive.html")
			return target, errors.New("redirect")
		}
		target, err := url.Parse("http://" + vm.IP.String())
		if err != nil {
			return nil, err
		}
		return target, nil
	case "internal":
		break // internal is done below
	}

	_, ok := proxy.RoutingTable[username]
	if !ok {
		return nil, errors.New("no users availalable in the db. targethost not found")
	}

	userConfig := proxy.RoutingTable[username]
	keyRoutingTable := userConfig.Services[servicename]

	v := len(keyRoutingTable.Keys)
	if v == 0 {
		return nil, fmt.Errorf("no keys are available for user %s", username)
	} else {
		if key == "latest" {
			// get all keys and sort them
			listOfKeys := make([]int, len(keyRoutingTable.Keys))
			i := 0
			for k, _ := range keyRoutingTable.Keys {
				listOfKeys[i], _ = strconv.Atoi(k)
				i++
			}
			sort.Ints(listOfKeys)

			// give precedence to the largest key number
			key = strconv.Itoa(listOfKeys[len(listOfKeys)-1])
		}

		_, ok := keyRoutingTable.Keys[key]
		if !ok {
			return nil, fmt.Errorf("no key %s is available for user %s", key, username)
		}

		// use round-robin algorithm for each hostname
		for i, value := range keyRoutingTable.Keys[key] {
			currentIndex := value.CurrentIndex
			if currentIndex == i {
				hostname = value.Host
				for k, _ := range keyRoutingTable.Keys[key] {
					if len(keyRoutingTable.Keys[key])-1 == currentIndex {
						keyRoutingTable.Keys[key][k].CurrentIndex = 0 // reached end
					} else {
						keyRoutingTable.Keys[key][k].CurrentIndex = currentIndex + 1
					}
				}
				break
			}
		}
	}

	target, err := url.Parse("http://" + hostname)
	if err != nil {
		return nil, err
	}

	return target, nil
}

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

func validateUser(user *UserInfo) (string, bool) {
	rules, ok := proxy.Rules[user.Username]
	if !ok { // if not available assume allowed for all
		return fmt.Sprintf("no rule available for servicename %s\n", user.Username), true
	}

	restriction, ok := rules.Services[user.Servicename]
	if !ok { // if not available assume allowed for all
		return fmt.Sprintf("no restriction available for servicename %s\n", user.Username), true
	}

	return validator(restriction, user).IP().Country().Check()
}
