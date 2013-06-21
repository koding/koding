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
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"strings"
)

type UserInfo struct {
	Domain       *proxyconfig.Domain
	IP           string
	Country      string
	Target       *url.URL
	Redirect     bool
	LoadBalancer *proxyconfig.LoadBalancer
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

func parseDomain(host string) (*UserInfo, error) {
	// remove www from the hostname (i.e. www.foo.com -> foo.com)
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
}

func (u *UserInfo) populateTarget() (io.Reader, error) {
	var err error
	var hostname string

	switch u.Domain.Proxy.Mode {
	case "maintenance":
		buf, err := executeTemplate("maintenance.html", nil)
		if err != nil {
			return nil, err
		}
		return buf, nil
	case "redirect":
		fullurl := u.Domain.Proxy.FullUrl
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
		case "roundrobin": // equal weights
			N := float64(len(u.Domain.HostnameAlias))
			n := int(math.Mod(float64(u.Domain.LoadBalancer.Index+1), N))
			hostname = u.Domain.HostnameAlias[n]

			u.Domain.LoadBalancer.Index = n
			go proxyDB.UpdateDomain(u.Domain)
		case "sticky":
			hostname = u.Domain.HostnameAlias[u.Domain.LoadBalancer.Index]
		case "random":
			randomIndex := rand.Intn(len(u.Domain.HostnameAlias) - 1)
			hostname = u.Domain.HostnameAlias[randomIndex]
		default:
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
			buf, errTemp := executeTemplate("notactiveVM.html", hostname)
			if errTemp != nil {
				return nil, errTemp
			}
			return buf, fmt.Errorf("vm is down: '%s'", err)
		}

		u.Target, err = url.Parse("http://" + vmAddr)
		if err != nil {
			return nil, err
		}
		u.LoadBalancer = &u.Domain.LoadBalancer

		return nil, nil
	case "internal":
		username := u.Domain.Proxy.Username
		servicename := u.Domain.Proxy.Servicename
		key := u.Domain.Proxy.Key

		keyData, err := proxyDB.GetKey(username, servicename, key)
		if err != nil {
			return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'", username, servicename, key)
		}

		switch keyData.LoadBalancer.Mode {
		case "roundrobin":
			N := float64(len(keyData.Host))
			n := int(math.Mod(float64(keyData.LoadBalancer.Index+1), N))
			hostname = keyData.Host[n]

			keyData.LoadBalancer.Index = n
			go proxyDB.UpdateKeyData(username, servicename, keyData)
		case "sticky":
			hostname = keyData.Host[keyData.LoadBalancer.Index]
		case "random":
			randomIndex := rand.Intn(len(keyData.Host) - 1)
			hostname = keyData.Host[randomIndex]
		default:
			hostname = keyData.Host[0]
		}

		if servicename == "broker" {
			u.Redirect = true
			hostname = "https://" + hostname
		} else {
			hostname = "http://" + hostname
		}

		u.Target, err = url.Parse(hostname)
		if err != nil {
			return nil, err
		}
		u.LoadBalancer = &keyData.LoadBalancer
		return nil, nil
	default:
		return nil, fmt.Errorf("ERROR: proxy mode is not supported: %s", u.Domain.Proxy.Mode)
	}

	return nil, nil
}

func validate(u *UserInfo) (bool, error) {
	// restrictionId, err := proxyDB.GetDomainRestrictionId(u.Domain.Id)
	// if err != nil {
	// 	return true, nil //don't block if we don't get a rule (pre-caution))
	// }

	restriction, err := proxyDB.GetRestrictionByDomain(u.Domain.Domain)
	if err != nil {
		return true, nil //don't block if we don't get a rule (pre-caution))
	}

	// restriction, err := proxyDB.GetRestrictionByID(restrictionId)
	// if err != nil {
	// 	return true, nil //don't block if we don't get a rule (pre-caution))
	// }

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
