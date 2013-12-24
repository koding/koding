package resolver

import (
	"container/ring"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontrolproxy/utils"
	"log"
	"math"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"labix.org/v2/mgo"
)

var (
	ErrGone = errors.New("target is gone")

	// cache lookup tables
	targetHosts   = make(map[string]*Target)
	targetHostsMu sync.Mutex // protects targetHosts map

	targetBuilds   = make(map[string]*Target)
	targetBuildsMu sync.Mutex // protects targetBuilds map

	// used for loadbalance modes, like roundrobin or random
	indexes   = make(map[string]int)
	indexesMu sync.Mutex // protect indexes
)

const (
	CookieBuildName  = "kdproxy-preferred-build"
	CookieDomainName = "kdproxy-preferred-domain"

	ModeMaintenance = "maintenance"
	ModeInternal    = "internal"
	ModeVM          = "vm"
	ModeVMOff       = "vmOff"
	ModeRedirect    = "redirect"
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

	// See struct models.Domain.Proxy
	CacheEnabled  bool
	CacheSuffixes string `bson:"cacheSuffixes"`
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

// GetTarget is used to get the target according to the incoming request
func GetTarget(req *http.Request) (*Target, error) {
	target, err := GetTargetByCookie(req)
	if err == nil {
		return target, nil
	}

	// if cookie is not set, use request host data, this is also a fallback
	return MemTargetByHost(req.Host)
}

// GetTargetByCookie looks if a request has set cookies to change the target.
// It looks for CookieBuildName and CookieDomainName.
func GetTargetByCookie(req *http.Request) (*Target, error) {
	cookieBuild, err := req.Cookie(CookieBuildName)
	if err == nil {
		targetBuild, err := MemTargetByBuild(cookieBuild.Value)
		if err == nil && targetBuild.Mode == ModeInternal {
			log.Printf("proxy target is overridden by cookie. Using BUILD '%s'\n", cookieBuild.Value)
			return targetBuild, nil
		}
	}

	cookieDomain, err := req.Cookie(CookieDomainName)
	if err == nil {
		targetDomain, err := MemTargetByHost(cookieDomain.Value)
		if err == nil && targetDomain.Mode == ModeInternal {
			log.Printf("proxy target is overrriden by cookie. Using DOMAIN '%s'\n", cookieDomain.Value)
			return targetDomain, nil
		}
	}

	return nil, errors.New("cookies are not set")
}

// TODO: make it an interface capable function and merge with MemTargetByHost
// MemTargetByBuild is like TargetByBuild with a difference, that it f first makes a
// lookup from the in-memory lookup, if not found it returns the result from
// TargetByBuild()
func MemTargetByBuild(host string) (*Target, error) {
	var err error
	target := new(Target)

	targetBuildsMu.Lock()
	defer targetBuildsMu.Unlock()

	target, ok := targetBuilds[host]
	if !ok || target.FetchedAt.Add(target.CacheTimeout).Before(time.Now()) {
		target, err = TargetByBuild(host)
		if err != nil {
			return nil, err
		}
		target.FetchedSource = "MongoDB"

		targetBuilds[host] = target
	} else {
		target.FetchedSource = "Cache"
	}

	return target, nil
}

// TargetByBuild is used the resolve the final target destination for the
// given build number.
func TargetByBuild(buildKey string) (*Target, error) {
	username := "koding"
	servicename := "server"

	target, err := buildTarget(username, servicename, buildKey)
	if err != nil {
		return nil, err
	}

	return newTarget(target, ModeInternal, time.Second*1), nil
}

// MemTargetByHost is like TargetByHost with a difference, that it f first makes a
// lookup from the in-memory lookup, if not found it returns the result from
// TargetByHost()
func MemTargetByHost(host string) (*Target, error) {
	var err error
	target := new(Target)

	targetHostsMu.Lock()
	defer targetHostsMu.Unlock()

	target, ok := targetHosts[host]
	if !ok || target.FetchedAt.Add(target.CacheTimeout).Before(time.Now()) {
		target, err = TargetByHost(host)
		if err != nil {
			return nil, err
		}
		target.FetchedSource = "MongoDB"

		targetHosts[host] = target
	} else {
		target.FetchedSource = "Cache"
	}

	return target, nil
}

// TargetByHost is used to resolve any hostname to their final target
// destination together with the mode of the domain for the given host string.
// Any incoming domain can have multiple different target destinations.
// TargetByHost returns the ultimate target destinations. Some examples:
//
// koding.com -> "http://webserver-build-koding-813a.in.koding.com:3000", mode:internal
// arslan.kd.io -> "http://10.128.2.25:80", mode:vm
// y.koding.com -> "http://localhost/maintenance", mode:maintenance
func TargetByHost(host string) (*Target, error) {
	var port string
	var err error

	if !utils.HasPort(host) {
		port = "80"
	} else {
		host, port, err = net.SplitHostPort(host)
		if err != nil {
			log.Println(err)
		}
	}

	domain, err := getDomain(host)
	if err != nil {
		return nil, err
	}

	target, err := targetMode(host, port, domain)
	if err != nil {
		return nil, err
	}

	target.CacheEnabled = domain.Proxy.CacheEnabled
	target.CacheSuffixes = domain.Proxy.CacheSuffixes
	return target, nil
}

func getDomain(host string) (*models.Domain, error) {
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

func targetMode(host, port string, domain *models.Domain) (*Target, error) {
	mode := domain.Proxy.Mode

	switch mode {
	case ModeMaintenance:
		// for avoiding nil pointer referencing
		return newTarget(nil, mode, time.Second*20), nil
	case ModeRedirect:
		target, err := url.Parse(utils.CheckScheme(domain.Proxy.FullUrl))
		if err != nil {
			return nil, err
		}

		return newTarget(target, mode, time.Second*20), nil
	case ModeVM:
		return vmTarget(host, port, domain)
	case ModeInternal:
		username := domain.Proxy.Username
		servicename := domain.Proxy.Servicename
		key := domain.Proxy.Key

		target, err := buildTarget(username, servicename, key)
		if err != nil {
			return nil, err
		}

		return newTarget(target, ModeInternal, time.Second*0), nil
	}

	return nil, fmt.Errorf("ERROR: proxy mode is not supported: %s", mode)
}

var (
	rings   = make(map[string]*ring.Ring)
	ringsMu sync.Mutex
)

// newSlice returns a new slice populated with the given ring items.
func newSlice(r *ring.Ring) []string {
	list := make([]string, r.Len())
	for i := 0; i < r.Len(); i++ {
		list[i] = r.Value.(string)
		r = r.Next()
	}

	return list
}

// newRing creates a new ring sturct populated with the given list items.
func newRing(list []string) *ring.Ring {
	r := ring.New(len(list))
	for _, val := range list {
		r.Value = val
		r = r.Next()
	}

	return r
}

// checkHosts checks each host for the given hosts slice and returns a new
// slice with healthy/alive ones.
func checkHosts(hosts []string) []string {
	healthyHosts := make([]string, 0)
	var wg sync.WaitGroup

	for _, host := range hosts {
		wg.Add(1)
		go func(host string) {
			defer wg.Done()

			log.Println("checking host", host)
			host = utils.AddPort(host, "80")
			err := utils.CheckServer(host)
			if err != nil {
				log.Println("error checking it", err)
			} else {
				healthyHosts = append(healthyHosts, host)
			}
		}(host)
	}

	wg.Wait()

	log.Println("alive hosts", healthyHosts)
	return healthyHosts
}

// healtChecker checks each host and updates the ring for the associated indexKey
func healtChecker(hosts []string, indexkey string) {
	log.Println("starting healtcheck with", hosts)
	for _ = range time.Tick(time.Second * 10) {
		healtyHosts := checkHosts(hosts)
		// replace hosts with healthy ones
		ringsMu.Lock()
		rings[indexkey] = newRing(healtyHosts)
		ringsMu.Unlock()
	}

}

// buildTarget returns a target that is obtained via the jProxyServices
// collection, which is used for internal services. An example service to
// target could be in form: "koding, server, 950" ->
// "webserver-950.sj.koding.com:3000".
func buildTarget(username, servicename, key string) (*url.URL, error) {
	var hostname string

	// generate unique key
	indexKey := fmt.Sprintf("%s-%s-%s", username, servicename, key)
	var r *ring.Ring
	var ok bool
	fmt.Println("indexkey is", indexKey)

	ringsMu.Lock()
	r, ok = rings[indexKey]
	if !ok {
		fmt.Println("no ring found, creating one")
		hosts, err := buildHosts(username, servicename, key)
		if err != nil {
			ringsMu.Unlock()
			return nil, err
		}

		fmt.Println("hosts created:", hosts)
		aliveHosts := checkHosts(hosts)
		fmt.Println("hosts alive  :", aliveHosts)

		r = newRing(aliveHosts)
		rings[indexKey] = r

		// start health checker for base hosts
		go healtChecker(hosts, indexKey)
	}
	ringsMu.Unlock()

	// get hostname and forward ring to the next value. the next value will be
	// used on the next request
	if r == nil {
		return nil, errors.New("no healthy hostname available")
	}

	hostname, ok = r.Value.(string)
	if !ok {
		return nil, fmt.Errorf("ring value is not string: %+v", r.Value)
	}

	fmt.Println("using hostname", hostname)
	rings[indexKey] = r.Next()

	// be sure that the hostname has scheme prependend
	hostname = utils.CheckScheme(hostname)
	target, err := url.Parse(hostname)
	if err != nil {
		return nil, err
	}

	return target, nil
}

// buildHosts returns a list of target hosts for the given build parameters.
func buildHosts(username, servicename, key string) ([]string, error) {
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
			return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'",
				username, servicename, key)
		}
	}

	if !keyData.Enabled {
		return nil, errors.New("host is not allowed to be used")
	}

	return keyData.Host, nil
}

// vmTarget returns a target that is obtained via the jVMs collections. The
// returned target's url is static and is not going to change. It is usually
// in form of "arslan.kd.io" -> "10.56.12.12". The default cacheTimeout is set
// to 0 seconds, means it will be cached forever (because it uses an IP that
// never change.)
func vmTarget(host, port string, domain *models.Domain) (*Target, error) {
	if len(domain.HostnameAlias) == 0 {
		return nil, fmt.Errorf("no hostnameAlias defined for host (vm): %s", host)
	}

	var hostname string

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
		return newTarget(nil, ModeVMOff, time.Second*20), nil
	}

	if vm.IP == nil {
		return newTarget(nil, ModeVMOff, time.Second*20), nil
	}

	vmAddr := vm.IP.String()
	if !utils.HasPort(vmAddr) {
		vmAddr = utils.AddPort(vmAddr, port)
	}

	target, err := url.Parse("http://" + vmAddr)
	if err != nil {
		return nil, err
	}

	return newTarget(target, domain.Proxy.Mode, time.Second*60), nil
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

	return modelhelper.NewDomain(host, ModeInternal, username, servicename, key, "", []string{}), nil
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
func getIndex(indexKey string) int {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	index, _ := indexes[indexKey]
	return index
}

// addOrUpdateIndex is used to add the current index for the current loadbalacne
// algorithm. The index number is changed according to to the loadbalance mode.
// When used roundrobin, the next items index is saved, for random a random
// number is assigned, and so on. It's concurrent-safe.
func addOrUpdateIndex(indexKey string, index int) {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	indexes[indexKey] = index
}

// deleteIndex is used to remove the current index from the indexes. It's
// concurrent-safe.
func deleteIndex(indexKey string) {
	indexesMu.Lock()
	defer indexesMu.Unlock()
	delete(indexes, indexKey)
}
