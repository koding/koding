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
	"sync"
	"time"
)

type Target struct {
	Url         *url.URL
	Mode        string
	Persistence string
	FetchedAt   time.Time
	UseCache    bool
}

func NewTarget(url *url.URL, mode, persistence string) *Target {
	if url == nil {
		url, _ = url.Parse("http://localhost/maintenance")
	}

	return &Target{
		Url:         url,
		Mode:        mode,
		Persistence: persistence,
		FetchedAt:   time.Now(),
		UseCache:    true,
	}
}

var proxyDB *proxyconfig.ProxyConfiguration
var ErrGone = errors.New("target is gone")

// used for inmemory lookup
var targets = make(map[string]Target)
var targetsLock sync.RWMutex
var cacheTimeout = time.Second * 20

// used for loadbalance modes, like roundrobin, random, etc..
var indexes = make(map[string]int)
var indexesLock sync.RWMutex

func init() {
	var err error
	proxyDB, err = proxyconfig.Connect()
	if err != nil {
		log.Fatalf("proxyconfig mongodb connect: %s", err)
	}
}

// GetMemTarget is like GetTarget with a difference, that it f first makes a
// lookup from the in-memory lookup, if not found it returns the result from
// GetTarget()
func GetMemTarget(host string) (*Target, string, error) {
	var err error
	var target = &Target{}
	dataSource := "cache"
	target, ok := getCacheTarget(host)
	if !ok {
		dataSource = "db"
		target, err = GetTarget(host)
		if err != nil {
			return nil, "", err
		}

		if target.UseCache {
			go registerCacheTarget(host, target)
		}
	}

	return target, dataSource, nil
}

// GetTarget is used to resolve any hostname to their final target destination
// together with the mode of the domain. Any incoming domain can have multiple
// different target destinations. GetTarget returns the ultimate target
// destinations. Some examples:
//
// koding.com -> "http://webserver-build-koding-813a.in.koding.com:3000", mode:internal
// arslan.kd.io -> "http://10.128.2.25:80", mode:vm
// y.koding.com -> "http://localhost/maintenance", mode:maintenance
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
		if len(domain.HostnameAlias) == 0 {
			return nil, fmt.Errorf("domain for hostname %s is not active")
		}

		switch domain.LoadBalancer.Mode {
		case "roundrobin": // equal weights
			index, ok := 0, false
			index, ok = getIndex(host)
			if !ok {
				index = domain.LoadBalancer.Index
				addOrUpdateIndex(host, index)
			}

			N := float64(len(domain.HostnameAlias))
			n := int(math.Mod(float64(index+1), N))

			hostname = domain.HostnameAlias[n]
			addOrUpdateIndex(host, n)
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
			index, ok := 0, false
			index, ok = getIndex(host)
			if !ok {
				index = keyData.LoadBalancer.Index
				addOrUpdateIndex(host, index)
			}

			hostname, n = roundRobin(keyData.Host, index, 0)
			addOrUpdateIndex(host, n)
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

// roundRobin is doing roundrobin between between the servers in the hosts
// array. If picks the next item in the array, specified with index and then
// checks for alivenes. If the server is dead it checks for the next item,
// until all servers are checked. If all servers are dead it returns an empty
// string, otherwise it returns the correct server name.
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

/*************************************************
*
*  in-memory lookup functions needed for cache lookups and actions
*
*************************************************/
func getCacheTarget(host string) (*Target, bool) {
	targetsLock.RLock()
	defer targetsLock.RUnlock()
	target, ok := targets[host]
	return &target, ok
}

func registerCacheTarget(host string, target *Target) {
	targetsLock.Lock()
	defer targetsLock.Unlock()
	targets[host] = *target
	if len(targets) == 1 {
		go cacheCleaner()
	}
}

func deleteCacheTarget(host string) {
	targetsLock.Lock()
	defer targetsLock.Unlock()
	delete(targets, host)
}

func cacheCleaner() {
	targetsLock.RLock()
	for len(targets) > 0 {
		var nextTime time.Time
		var nextTarget string
		for ip, c := range targets {
			if nextTime.IsZero() || c.FetchedAt.Before(nextTime) {
				nextTime = c.FetchedAt
				nextTarget = ip
			}
		}
		targetsLock.RUnlock()
		// negative duration is no-op, means it will not panic
		time.Sleep(cacheTimeout - time.Now().Sub(nextTime))
		deleteCacheTarget(nextTarget)
		targetsLock.RLock()
	}
	targetsLock.RUnlock()
}

/*************************************************
*
*  the following functions are used for loadbalance indexing.
*
*************************************************/

// getIndex is used to get the current index for current the loadbalance
// algorithm. It's concurrent-safe.
func getIndex(host string) (int, bool) {
	indexesLock.RLock()
	defer indexesLock.RUnlock()
	index, ok := indexes[host]
	return index, ok
}

// addOrUpdateIndex is used to add the current index for the current loadbalacne
// algorithm. The index number is changed according to to the loadbalance mode.
// When used roundrobin, the next items index is saved, for random a random
// number is assigned, and so on. It's concurrent-safe.
func addOrUpdateIndex(host string, index int) {
	indexesLock.Lock()
	defer indexesLock.Unlock()
	indexes[host] = index
}

// deleteIndex is used to remove the current index from the indexes. It's
// concurrent-safe.
func deleteIndex(host string) {
	indexesLock.Lock()
	defer indexesLock.Unlock()
	delete(indexes, host)
}
