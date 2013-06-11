package main

import (
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
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
	Domain   *proxyconfig.Domain
	IP       string
	Country  string
	Target   *url.URL
	Redirect bool
}

func NewUserInfo(domain *proxyconfig.Domain) *UserInfo {
	return &UserInfo{
		Domain: domain,
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

	fmt.Printf("--\nmode '%s'\t: %s %s\n", user.Domain.Proxy.Mode, user.IP, user.Country)
	fmt.Printf("proxy from\t: %s --> %s\n", user.Domain.Domain, user.Target.Host)
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
	var hostname string

	username := u.Domain.Proxy.Username
	servicename := u.Domain.Proxy.Servicename
	key := u.Domain.Proxy.Key
	fullurl := u.Domain.Proxy.FullUrl

	switch u.Domain.Proxy.Mode {
	case "direct":
		u.Target, err = url.Parse("http://" + fullurl)
		if err != nil {
			return err
		}
		return nil
	case "vm":
		switch u.Domain.LoadBalancer.Mode {
		case "roundrobin":
			N := float64(len(u.Domain.HostnameAlias))
			n := int(math.Mod(float64(u.Domain.LoadBalancer.Index+1), N))
			hostname = u.Domain.HostnameAlias[n]

			u.Domain.LoadBalancer.Index = n
			go proxyDB.UpdateDomain(u.Domain)
		case "sticky":
			hostname = u.Domain.HostnameAlias[u.Domain.LoadBalancer.Index]
			// sessionName := fmt.Sprintf("kodingproxy-%s-%s", u.Domain.Domain, u.IP)
			// // We're ignoring the error resulted from decoding an existing
			// // session: Get() always returns a session, even if empty.
			// session, _ := store.Get(req, sessionName)
			// _, ok := session.Values["JSESSIONID"]
		case "default":
			hostname = u.Domain.HostnameAlias[0]
		}

		var vm virt.VM
		if err := db.VMs.Find(bson.M{"hostnameAlias": hostname}).One(&vm); err != nil {
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
	// Then make a lookup for domains
	domain, err := proxyDB.GetDomain(host)
	if err != nil {
		if err != mgo.ErrNotFound {
			return &UserInfo{}, fmt.Errorf("domain lookup error '%s'", err)
		}

		// lookup didn't found anything, move on to .x.koding.com domains
		if strings.HasSuffix(host, "x.koding.com") {
			// hostsin form {name}-{key}.kd.io or {name}-{key}.x.koding.com is used by koding
			subdomain := strings.TrimSuffix(host, ".x.koding.com")
			servicename := strings.Split(subdomain, "-")[0]
			key := strings.Split(subdomain, "-")[1]

			domain := proxyconfig.NewDomain(host, "internal", "koding", servicename, key, "", []string{})
			return NewUserInfo(domain), nil
		}

		return &UserInfo{}, fmt.Errorf("domain %s is unknown.", host)
	}

	return NewUserInfo(&domain), nil

	// // Handle kd.io domains first
	// if strings.HasSuffix(host, "kd.io") {
	// 	return NewUserInfo("", "", "", "", "vm", host), nil
	// }

	//
	// 	switch counts := strings.Count(host, "-"); {
	// 	case counts == 1:
	// 		// host is in form {name}-{key}.kd.io, used by koding
	// 		subdomain := strings.TrimSuffix(host, ".kd.io")
	// 		servicename := strings.Split(subdomain, "-")[0]
	// 		key := strings.Split(subdomain, "-")[1]
	//
	// 		return NewUserInfo("koding", servicename, key, "", "internal", host), nil
	// 	case counts > 1:
	// 		// host is in form {name}-{key}-{username}.kd.io, used by users
	// 		firstSub := strings.Split(host, ".")[0]
	//
	// 		partsSecond := strings.SplitN(firstSub, "-", 3)
	// 		servicename := partsSecond[0]
	// 		key := partsSecond[1]
	// 		username := partsSecond[2]
	//
	// 		return NewUserInfo(username, servicename, key, "", "internal", host), nil
	// 	}
	// return &UserInfo{}, fmt.Errorf("no data available for proxy. can't parse domain %s", host)
}

func validate(u *UserInfo) (bool, error) {

	ruleId, err := proxyDB.GetDomainRuleId(u.Domain.Id)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	rule, err := proxyDB.GetRuleByID(ruleId)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	// res, err := proxyDB.GetRule(u.Domain.Domainname)
	// if err != nil {
	// 	return true, nil //don't block if we don't get a rule (pre-caution))
	// }

	return validator(rule, u).IP().Country().Check()
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
