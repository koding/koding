package resolver

import (
	"errors"
	"fmt"
	"koding/kontrol/kontrolproxy/proxyconfig"
	"koding/kontrol/kontrolproxy/utils"
	"labix.org/v2/mgo"
	"log"
	"math"
	"math/rand"
	"net"
	"net/url"
	"strconv"
	"strings"
)

type Target struct {
	Url         *url.URL
	Mode        string
	Persistence string
}

func NewTarget(url *url.URL, mode, persistence string) *Target {
	if url == nil {
		url, _ = url.Parse("http://localhost/maintenance")
	}

	return &Target{
		Url:         url,
		Mode:        mode,
		Persistence: persistence,
	}
}

var proxyDB *proxyconfig.ProxyConfiguration
var ErrGone = errors.New("target is gone")

func init() {
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}
}

func GetTarget(host string) (*Target, error) {
	var target *url.URL
	var domain proxyconfig.Domain
	var hostname string
	var err error
	var port string

	if !utils.HasPort(host) {
		port = "80"
	} else {
		host, port, err = net.SplitHostPort(host)
		if err != nil {
			log.Println(err)
		}
	}

	domain, err = proxyDB.GetDomain(host)
	if err != nil {
		if err != mgo.ErrNotFound {
			return nil, fmt.Errorf("incoming req host: %s, domain lookup error '%s'\n", host, err.Error())
		}

		// lookup didn't found anything, move on to .x.koding.com domains
		if strings.HasSuffix(host, "x.koding.com") {
			if c := strings.Count(host, "-"); c != 1 {
				return nil, fmt.Errorf("not valid req host", host)
			}
			subdomain := strings.TrimSuffix(host, ".x.koding.com")
			servicename := strings.Split(subdomain, "-")[0]
			key := strings.Split(subdomain, "-")[1]
			domain = *proxyconfig.NewDomain(host, "internal", "koding", servicename, key, "", []string{})
		} else {
			return nil, fmt.Errorf("domain %s is unknown", host)
		}
	}

	mode := domain.Proxy.Mode
	persistence := domain.LoadBalancer.Persistence

	switch mode {
	case "maintenance":
		// for avoiding nil pointer referencing
		return NewTarget(nil, mode, persistence), nil
	case "redirect":
		target, err := url.Parse(domain.Proxy.FullUrl)
		if err != nil {
			return nil, err
		}

		return NewTarget(target, mode, persistence), nil
	case "vm":
		switch domain.LoadBalancer.Mode {
		case "roundrobin": // equal weights
			N := float64(len(domain.HostnameAlias))
			n := int(math.Mod(float64(domain.LoadBalancer.Index+1), N))
			hostname = domain.HostnameAlias[n]
			domain.LoadBalancer.Index = n
			go proxyDB.UpdateDomain(&domain)
		case "sticky":
			hostname = domain.HostnameAlias[domain.LoadBalancer.Index]
		case "random":
			randomIndex := rand.Intn(len(domain.HostnameAlias) - 1)
			hostname = domain.HostnameAlias[randomIndex]
		default:
			hostname = domain.HostnameAlias[0]
		}

		vm, err := proxyDB.GetVM(hostname)
		if err != nil {
			return nil, err
		}

		if vm.IP == nil {
			return nil, fmt.Errorf("vm for hostname %s is not active", hostname)
		}

		vmAddr := vm.IP.String()
		if !utils.HasPort(vmAddr) {
			vmAddr = utils.AddPort(vmAddr, port)
		}

		target, err = url.Parse("http://" + vmAddr)
		if err != nil {
			return nil, err
		}
	case "internal":
		username := domain.Proxy.Username
		servicename := domain.Proxy.Servicename
		key := domain.Proxy.Key
		latestKey := proxyDB.GetLatestKey(username, servicename)
		if latestKey == "" {
			latestKey = key
		}

		keyData, err := proxyDB.GetKey(username, servicename, key)
		if err != nil {
			currentVersion, _ := strconv.Atoi(key)
			latestVersion, _ := strconv.Atoi(latestKey)
			if currentVersion < latestVersion {
				return nil, ErrGone
			} else {
				return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'", username, servicename, key)
			}
		}

		switch keyData.LoadBalancer.Mode {
		case "roundrobin":
			var n int
			hostname, n = roundRobin(keyData.Host, keyData.LoadBalancer.Index, 0)
			keyData.LoadBalancer.Index = n
			go proxyDB.UpdateKeyData(username, servicename, keyData)
			if hostname == "" {
				return NewTarget(nil, "maintenance", persistence), nil
			}
		case "sticky":
			hostname = keyData.Host[keyData.LoadBalancer.Index]
		case "random":
			randomIndex := rand.Intn(len(keyData.Host) - 1)
			hostname = keyData.Host[randomIndex]
		default:
			hostname = keyData.Host[0]
		}

		if !strings.HasPrefix(hostname, "http://") {
			hostname = "http://" + hostname
		}

		target, err = url.Parse(hostname)
		if err != nil {
			return nil, err
		}
	default:
		return nil, fmt.Errorf("ERROR: proxy mode is not supported: %s", domain.Proxy.Mode)
	}

	return NewTarget(target, mode, persistence), nil
}

func roundRobin(hosts []string, index, iter int) (string, int) {
	if iter == len(hosts) {
		return "", 0 // all hosts are dead
	}

	N := float64(len(hosts))
	n := int(math.Mod(float64(index+1), N))
	hostname := hosts[n]

	if err := utils.CheckServer(hostname); err != nil {
		hostname, n = roundRobin(hosts, index+1, iter+1)
	}

	return hostname, n
}
