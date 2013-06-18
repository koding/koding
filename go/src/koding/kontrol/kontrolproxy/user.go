package main

import (
	"errors"
	"fmt"
	"io"
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
	Domain  *proxyconfig.Domain
	IP      string
	Country string
	Target  *url.URL
}

func NewUserInfo(domain *proxyconfig.Domain) *UserInfo {
	return &UserInfo{
		Domain: domain,
	}
}

func populateUser(outreq *http.Request) (*UserInfo, io.Reader, error) {
	user, err := parseDomain(outreq.Host)
	if err != nil {
		return nil, nil, err
	}

	user.IP, _, err = net.SplitHostPort(outreq.RemoteAddr)
	if err == nil {
		if geoIP != nil {
			loc := geoIP.GetLocationByIP(user.IP)
			if loc != nil {
				user.Country = loc.CountryName
			}
		}
	}

	buf, err := user.populateTarget()
	if err != nil {
		return nil, buf, err
	}

	fmt.Printf("--\nmode '%s'\t: %s %s\n", user.Domain.Proxy.Mode, user.IP, user.Country)
	return user, buf, nil
}

func (u *UserInfo) populateTarget() (io.Reader, error) {
	var err error
	var hostname string

	username := u.Domain.Proxy.Username
	servicename := u.Domain.Proxy.Servicename
	key := u.Domain.Proxy.Key
	fullurl := u.Domain.Proxy.FullUrl

	switch u.Domain.Proxy.Mode {
	case "maintenance":
		buf, err := executeTemplate("maintenance.html", nil)
		if err != nil {
			return nil, err
		}
		return buf, nil
	case "redirect":
		if !strings.HasPrefix(fullurl, "http://") && !strings.HasPrefix(fullurl, "https://") {
			fullurl = "https://" + fullurl
		}

		u.Target, err = url.Parse(fullurl)
		if err != nil {
			return nil, err
		}
		return nil, nil
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
		case "default", "":
			hostname = u.Domain.HostnameAlias[0]
		}

		var vm virt.VM
		if err := db.VMs.Find(bson.M{"hostnameAlias": hostname}).One(&vm); err != nil {
			buf, err := executeTemplate("notfound.html", hostname)
			if err != nil {
				return nil, err
			}

			return buf, errors.New("vm not found")
		}
		if vm.IP == nil {
			buf, err := executeTemplate("notactiveVM.html", hostname)
			if err != nil {
				return nil, err
			}

			return buf, errors.New("vm not active")
		}

		vmAddr := vm.IP.String()
		if !hasPort(vmAddr) {
			vmAddr = addPort(vmAddr, "80")
		}

		err := checkServer(vmAddr)
		if err != nil {
			buf, err := executeTemplate("notactiveVM.html", hostname)
			if err != nil {
				return nil, err
			}
			return buf, errors.New("vm is down")
		}

		u.Target, err = url.Parse("http://" + vmAddr)
		if err != nil {
			return nil, err
		}

		return nil, nil
	case "internal":
		break // internal is done below
	}

	keyData, err := proxyDB.GetKey(username, servicename, key)
	if err != nil {
		return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'", username, servicename, key)
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
		return nil, err
	}

	return nil, nil
}

func parseDomain(host string) (*UserInfo, error) {
	// forward www.foo.com to foo.com
	if strings.HasPrefix(host, "www.") {
		host = strings.TrimPrefix(host, "www.")
	}

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
	restrictionId, err := proxyDB.GetDomainRestrictionId(u.Domain.Id)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	restriction, err := proxyDB.GetRestrictionByID(restrictionId)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	return validator(restriction, u).AddRules().Check()
}

func isWebsocket(req *http.Request) bool {
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

func logDomainRequests(domain string) {
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainRequests(domain)
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

func logDomainDenied(domain, ip, country, reason string) {
	if domain == "" {
		return
	}

	err := proxyDB.AddDomainDenied(domain, ip, country, reason)
	if err != nil {
		fmt.Printf("could not add domain statistisitcs for %s\n", err.Error())
	}
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
