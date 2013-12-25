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
	targets   = make(map[string]*Target)
	targetsMu sync.Mutex // protects targets map

	// used for loadbalance modes, like roundrobin or random
	indexes   = make(map[string]int)
	indexesMu sync.Mutex // protect indexes

	// our load balancer roundrobin maps. Key is created for each index key.
	rings   = make(map[string]*ring.Ring)
	ringsMu sync.Mutex
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
	Mode     string
	ModeData string

	// FetchedAt contains the time the target was fetched and stored in our
	// internal map. Useful for caching.
	FetchedAt time.Time

	// FetchedSource contains the source information from which the target is
	// obtained.
	FetchedSource string

	// CacheTimeout is used to invalidate the target. Zero duration disables the cache.
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

// GetTarget is used to get the target according to the incoming request it
// looks if a request has set cookies to change the target. If not it
// fallbacks to request host data.
func GetTarget(req *http.Request) (*Target, error) {
	cookieBuild, err := req.Cookie(CookieBuildName)
	if err == nil {
		key := routeKey{
			username:    "koding",
			servicename: "server",
			build:       cookieBuild.Value,
		}

		targetBuild, err := buildTarget(key)
		if err == nil && targetBuild.Mode == ModeInternal {
			log.Printf("proxy target is overridden by cookie. Using BUILD '%s'\n", cookieBuild.Value)
			return targetBuild, nil
		}
	}

	cookieDomain, err := req.Cookie(CookieDomainName)
	if err == nil {
		targetDomain, err := TargetByHost(cookieDomain.Value)
		if err == nil && targetDomain.Mode == ModeInternal {
			log.Printf("proxy target is overrriden by cookie. Using DOMAIN '%s'\n", cookieDomain.Value)
			return targetDomain, nil
		}
	}

	// if cookie is not set, use request host data, this is also a fallback
	return TargetByHost(req.Host)
}

type routeKey struct {
	username    string
	servicename string
	build       string
}

func (r *routeKey) String() string {
	return fmt.Sprintf("%s-%s-%s", r.username, r.servicename, r.build)
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

	var target *Target
	var ok bool

	targetsMu.Lock()
	target, ok = targets[host]
	if ok && time.Now().Before(target.FetchedAt.Add(target.CacheTimeout)) {
		targetsMu.Unlock()
		fmt.Println("using cache")
		target.FetchedSource = "Cache"
		return target, nil
	}
	targetsMu.Unlock()
	fmt.Println("using db")

	domain, err := getDomain(host)
	if err != nil {
		return nil, err
	}

	target, err = targetMode(host, port, domain)
	if err != nil {
		return nil, err
	}

	target.CacheEnabled = domain.Proxy.CacheEnabled
	target.CacheSuffixes = domain.Proxy.CacheSuffixes
	target.FetchedSource = "MongoDB"

	targetsMu.Lock()
	targets[host] = target
	targetsMu.Unlock()

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
		key := routeKey{
			username:    domain.Proxy.Username,
			servicename: domain.Proxy.Servicename,
			build:       domain.Proxy.Key,
		}

		return buildTarget(key)
	}

	return nil, fmt.Errorf("ERROR: proxy mode is not supported: %s", mode)
}

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

func CleanRingCache() {
	ringsMu.Lock()
	defer ringsMu.Unlock()

	// purge rings, that means
	rings = make(map[string]*ring.Ring)
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
func buildTarget(key routeKey) (*Target, error) {
	var hostname string
	var r *ring.Ring
	var ok bool
	fmt.Println("indexkey is", key)

	ringsMu.Lock()
	r, ok = rings[key.String()]
	if !ok {
		fmt.Println("no ring found, creating one")
		hosts, err := buildHosts(key)
		if err != nil {
			ringsMu.Unlock()
			return nil, err
		}

		fmt.Println("hosts created:", hosts)
		aliveHosts := checkHosts(hosts)
		fmt.Println("hosts alive  :", aliveHosts)

		r = newRing(aliveHosts)
		rings[key.String()] = r

		// start health checker for base hosts
		go healtChecker(hosts, key.String())
	}
	ringsMu.Unlock()

	// means the healtChecker created a zero length ring. This is caused only
	// when all hosts are sick.
	if r == nil {
		return nil, errors.New("no healthy hostname available")
	}

	// get hostname and forward ring to the next value. the next value will be
	// used on the next request
	hostname, ok = r.Value.(string)
	if !ok {
		return nil, fmt.Errorf("ring value is not string: %+v", r.Value)
	}

	fmt.Println("using hostname", hostname)
	rings[key.String()] = r.Next()

	// be sure that the hostname has scheme prependend
	hostname = utils.CheckScheme(hostname)
	targetURL, err := url.Parse(hostname)
	if err != nil {
		return nil, err
	}

	return newTarget(targetURL, ModeInternal, time.Second*0), nil
}

// buildHosts returns a list of target hosts for the given build parameters.
func buildHosts(key routeKey) ([]string, error) {
	latestKey := modelhelper.GetLatestKey(key.username, key.servicename)
	if latestKey == "" {
		latestKey = key.build
	}

	keyData, err := modelhelper.GetKey(key.username, key.servicename, key.build)
	if err != nil {
		currentVersion, _ := strconv.Atoi(key.build)
		latestVersion, _ := strconv.Atoi(latestKey)
		if currentVersion < latestVersion {
			return nil, ErrGone
		} else {
			return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'",
				key.username, key.servicename, key.build)
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
