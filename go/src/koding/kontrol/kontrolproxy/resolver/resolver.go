package resolver

import (
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
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

// Target is returned for every incoming request host.
type Target struct {
	// Url contains the final target
	Url *url.URL

	// Mode contains the information get via model.ProxyTable.Mode. It is used
	// to make specific lookups for incoming hosts, or return special targets.
	// Some examples are: "vm", "redirect", "internal" and so on.
	Mode string

	// FetchedAt contains the time the target was fetched and stored in our
	// internal map. Useful for caching.
	FetchedAt time.Time

	// FetchedSource contains the source information from which the target is
	// obtained.
	FetchedSource string

	// CacheTimeout is used to invalidate the target. If no timeout is given,
	// it caches it forever (works only if UseCache is true).
	CacheTimeout time.Duration
}

func newTarget(url *url.URL, mode string, timeout time.Duration) *Target {
	if url == nil {
		url, _ = url.Parse("http://localhost/maintenance")
	}

	return &Target{
		Url:          url,
		Mode:         mode,
		FetchedAt:    time.Now(),
		CacheTimeout: timeout,
	}
}

var ErrGone = errors.New("target is gone")

// cache lookup table
var targets = make(map[string]*Target)
var targetsMu sync.Mutex // protects targets map

// used for loadbalance modes, like roundrobin or random
var indexes = make(map[string]int)
var indexesMu sync.Mutex // protect indexes

// GetMemTarget is like GetTarget with a difference, that it f first makes a
// lookup from the in-memory lookup, if not found it returns the result from
// GetTarget()
func GetMemTarget(host string) (*Target, error) {
	var err error
	target := new(Target)

	targetsMu.Lock()
	defer targetsMu.Unlock()

	target, ok := targets[host]
	if !ok || target.FetchedAt.Add(target.CacheTimeout).Before(time.Now()) {
		target, err = GetTarget(host)
		if err != nil {
			return nil, err
		}
		target.FetchedSource = "MongoDB"

		targets[host] = target
	} else {
		target.FetchedSource = "Cache"
	}

	return target, nil
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
	var err error
	var port string

	// split host and port and also check if incoming host has a port
	if !utils.HasPort(host) {
		port = "80"
	} else {
		host, port, err = net.SplitHostPort(host)
		if err != nil {
			log.Println(err)
		}
	}

	domain, err := targetDomain(host)
	if err != nil {
		return nil, err
	}

	mode := domain.Proxy.Mode
	switch mode {
	case "maintenance":
		// for avoiding nil pointer referencing
		return newTarget(nil, mode, time.Second*20), nil
	case "redirect":
		target, err := url.Parse(utils.CheckScheme(domain.Proxy.FullUrl))
		if err != nil {
			return nil, err
		}

		return newTarget(target, mode, time.Second*20), nil
	case "vm":
		return vmTarget(host, port, domain)
	case "internal":
		return internalTarget(host, port, domain)
	}

	return nil, fmt.Errorf("ERROR: proxy mode is not supported: %s", domain.Proxy.Mode)
}

func targetDomain(host string) (*models.Domain, error) {
	domain := new(models.Domain)
	var err error
	domain, err = modelhelper.GetDomain(host)
	if err != nil {
		if err != mgo.ErrNotFound {
			return nil, fmt.Errorf("incoming req host: %s, domain lookup error '%s'\n", host, err.Error())
		}

		domain, err = fallbackDomain(host)
		if err != nil {
			return nil, err
		}
	}

	if domain.Proxy == nil {
		return nil, fmt.Errorf("proxy field is empty for %s", host)
	}

	if domain.Proxy.Mode == "" {
		return nil, fmt.Errorf("proxy mode field is empty for %s", host)
	}

	return domain, nil
}

// internalTarget returns a target that is obtained via the jProxyServices
// collection, which is used for internal services. An example host to target
// could be in form of: "koding.com" -> webserver-950.sj.koding.com:3000".
// The default cacheTimeout is 20 seconds.
func internalTarget(host, port string, domain *models.Domain) (*Target, error) {
	var hostname string
	// we only opened ports between those, therefore other ports are not used
	portInt, _ := strconv.Atoi(port)
	if portInt >= 1024 && portInt <= 10000 {
		return nil, fmt.Errorf("port range is not allowed for internal usages")
	}

	username := domain.Proxy.Username
	servicename := domain.Proxy.Servicename
	key := domain.Proxy.Key
	latestKey := modelhelper.GetLatestKey(username, servicename)
	if latestKey == "" {
		latestKey = key
	}

	keyData, err := modelhelper.GetKey(username, servicename, key)
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
		index := getIndex(host) // gives 0 if not available
		hostname, n = internalRoundRobin(keyData.Host, index, 0)
		addOrUpdateIndex(host, n)
		if hostname == "" { // means all servers are dead, show maintenance page
			return newTarget(nil, "maintenance", time.Second*20), nil
		}
	case "random":
		randomIndex := rand.Intn(len(keyData.Host) - 1)
		hostname = keyData.Host[randomIndex]
	default:
		hostname = keyData.Host[0]
	}

	hostname = utils.CheckScheme(hostname)
	target, err := url.Parse(hostname)
	if err != nil {
		return nil, err
	}

	return newTarget(target, domain.Proxy.Mode, time.Second*20), nil
}

// vmTarget returns a target that is obtained via the jVMs collections. The
// returned target's url is static and is not going to change. It is usually
// in form of "arslan.kd.io" -> "10.56.12.12". The default cacheTimeout is set
// to 0 seconds, means it will be cached forever (because it uses an IP that
// never change.)
func vmTarget(host, port string, domain *models.Domain) (*Target, error) {
	var hostname string

	if len(domain.HostnameAlias) == 0 {
		return nil, fmt.Errorf("domain for hostname %s is not active")
	}

	switch domain.LoadBalancer.Mode {
	case "roundrobin": // equal weights
		index := getIndex(host) // gives 0 if not available
		N := float64(len(domain.HostnameAlias))
		n := int(math.Mod(float64(index+1), N))
		hostname = domain.HostnameAlias[n]

		addOrUpdateIndex(host, n)
	case "random":
		randomIndex := rand.Intn(len(domain.HostnameAlias) - 1)
		hostname = domain.HostnameAlias[randomIndex]
	default:
		hostname = domain.HostnameAlias[0]
	}

	vm, err := modelhelper.GetVM(hostname)
	if err != nil {
		return nil, err
	}

	if vm.HostKite == "" {
		return newTarget(nil, "vmOff", time.Second*20), nil
	}

	if vm.IP == nil {
		return newTarget(nil, "vmOff", time.Second*20), nil
	}

	vmAddr := vm.IP.String()
	if !utils.HasPort(vmAddr) {
		vmAddr = utils.AddPort(vmAddr, port)
	}

	target, err := url.Parse("http://" + vmAddr)
	if err != nil {
		return nil, err
	}

	// cache VM's target for one day, they have static IP's and don't never change
	return newTarget(target, domain.Proxy.Mode, time.Hour*24), nil
}

// fallbackDomain is used to return a fallback domain when the incoming host
// is not availaible in our Domains collection. This is usefull for dynamic
// url's like "server-123.x.koding.com" or "awesomekite-1-arslan.kd.io" you
// can overide the incoming host  always by adding a new entry for the domain
// itself into to jDomains collection.
func fallbackDomain(host string) (*models.Domain, error) {
	h := strings.SplitN(host, ".", 2) // input: xxxxx.kd.io, output: [xxxxx kd.io]

	if len(h) != 2 {
		return notValidDomainFor(host)
	}

	var servicename, key, username string
	s := strings.Split(h[0], "-") // input: service-key-username, output: [service key username]

	switch h[1] {
	case "x.koding.com":
		// in form of: server-123.x.koding.com, assuming the user is 'koding'
		fmt.Println("X.KODING.COM", host)
		if c := strings.Count(h[0], "-"); c != 1 {
			return notValidDomainFor(host)
		}
		servicename, key, username = s[0], s[1], "koding"
	case "kd.io":
		// in form of: chatkite-1-arslan.kd.io
		//           : webserver-917-fatih.kd.io
		fmt.Println("KD.IO", host)
		if c := strings.Count(h[0], "-"); c != 2 {
			return notValidDomainFor(host)
		}
		servicename, key, username = s[0], s[1], s[2]
	default:
		// any other domains are discarded
		return notValidDomainFor(host)
	}

	if servicename == "" || key == "" || username == "" {
		return notValidDomainFor(host)
	}

	return modelhelper.NewDomain(host, "internal", username, servicename, key, "", []string{}), nil
}

func notValidDomainFor(host string) (*models.Domain, error) {
	return nil, fmt.Errorf("not valid req host: '%s'", host)
}

// internalRoundRobin is doing roundrobin between between the servers in the hosts
// array. If picks the next item in the array, specified with index and then
// checks for aliveness. If the server is dead it checks for the next item,
// until all servers are checked. If all servers are dead it returns an empty
// string, otherwise it returns the correct server name.
func internalRoundRobin(hosts []string, index, iter int) (string, int) {
	if iter == len(hosts) {
		return "", 0 // all hosts are dead
	}

	N := float64(len(hosts))
	n := int(math.Mod(float64(index+1), N))
	hostname := hosts[n]

	if err := utils.CheckServer(hostname); err != nil {
		hostname, n = internalRoundRobin(hosts, index+1, iter+1)
	}

	return hostname, n
}

/*******************************************************
*
*  loadbalance index functions for roundrobin or random
*
********************************************************/

// getIndex is used to get the current index for current the loadbalance
// algorithm/mode. It's concurrent-safe.
func getIndex(host string) int {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	index, _ := indexes[host]
	return index
}

// addOrUpdateIndex is used to add the current index for the current loadbalacne
// algorithm. The index number is changed according to to the loadbalance mode.
// When used roundrobin, the next items index is saved, for random a random
// number is assigned, and so on. It's concurrent-safe.
func addOrUpdateIndex(host string, index int) {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	indexes[host] = index
}

// deleteIndex is used to remove the current index from the indexes. It's
// concurrent-safe.
func deleteIndex(host string) {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	delete(indexes, host)
}
