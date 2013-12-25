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
	"sync"
	"time"
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
	// URL contains the final target
	URL *url.URL

	// A list of hosts
	HostnameAlias []string

	// Information used to resolve to the final target.
	Proxy *models.ProxyTable

	// FetchedAt contains the time the target was fetched and stored in our
	// internal map. Useful for caching.
	FetchedAt time.Time

	// FetchedSource contains the source information from which the target is
	// obtained.
	FetchedSource string

	// CacheTimeout is used to invalidate the target. Zero duration disables the cache.
	CacheTimeout time.Duration
}

// GetTarget is used to get the target according to the incoming request it
// looks if a request has set cookies to change the target. If not it
// fallbacks to request host data.
func GetTarget(req *http.Request) (*Target, error) {
	cookieBuild, err := req.Cookie(CookieBuildName)
	if err == nil {
		service := service{
			username:    "koding",
			servicename: "server",
			build:       cookieBuild.Value,
		}

		t, err := service.target()
		if err == nil {
			log.Printf("proxy target is overridden by cookie build: '%s'\n", cookieBuild.Value)
			return t, nil
		}
	}

	cookieDomain, err := req.Cookie(CookieDomainName)
	if err == nil {
		t, err := TargetByHost(cookieDomain.Value)
		if err == nil {
			log.Printf("proxy target is overrriden by cookie domain: '%s'\n", cookieDomain.Value)
			return t, nil
		}
	}

	// if cookie is not set, use request host data, this is also a fallback
	return TargetByHost(req.Host)
}

type service struct {
	username    string
	servicename string
	build       string
}

func (s *service) String() string {
	return fmt.Sprintf("%s-%s-%s", s.username, s.servicename, s.build)
}

func (s *service) target() (*Target, error) {
	u, err := s.resolve()
	if err != nil {
		return nil, err
	}

	t := &Target{
		URL:       u,
		FetchedAt: time.Now(),
	}

	return t, nil
}

// buildTarget returns a target that is obtained via the jProxyServices
// collection, which is used for internal services. An example service to
// target could be in form: "koding, server, 950" ->
// "webserver-950.sj.koding.com:3000".
func (s *service) resolve() (*url.URL, error) {
	var hostname string
	var r *ring.Ring
	var ok bool

	indexkey := s.String()
	fmt.Println("indexkey is", indexkey)

	ringsMu.Lock()
	r, ok = rings[indexkey]
	if !ok {
		fmt.Println("no ring found, creating one")
		hosts, err := s.serviceHosts()
		if err != nil {
			ringsMu.Unlock()
			return nil, err
		}

		fmt.Println("hosts created:", hosts)
		aliveHosts := checkHosts(hosts)
		fmt.Println("hosts alive  :", aliveHosts)

		r = newRing(aliveHosts)
		rings[indexkey] = r

		// start health checker for base hosts
		go healtChecker(hosts, indexkey)
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
	ringsMu.Lock()
	rings[indexkey] = r.Next()
	ringsMu.Unlock()

	// be sure that the hostname has scheme prependend
	hostname = utils.CheckScheme(hostname)
	targetURL, err := url.Parse(hostname)
	if err != nil {
		return nil, err
	}

	return targetURL, nil
}

// buildHosts returns a list of target hosts for the given build parameters.
func (s *service) serviceHosts() ([]string, error) {
	latestKey := modelhelper.GetLatestKey(s.username, s.servicename)
	if latestKey == "" {
		latestKey = s.build
	}

	keyData, err := modelhelper.GetKey(s.username, s.servicename, s.build)
	if err != nil {
		currentVersion, _ := strconv.Atoi(s.build)
		latestVersion, _ := strconv.Atoi(latestKey)
		if currentVersion < latestVersion {
			return nil, ErrGone
		} else {
			return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'",
				s.username, s.servicename, s.build)
		}
	}

	if !keyData.Enabled {
		return nil, errors.New("host is not allowed to be used")
	}

	return keyData.Host, nil
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

	target.Proxy = domain.Proxy
	target.HostnameAlias = domain.HostnameAlias

	err = target.resolve(host, port)
	if err != nil {
		return nil, err
	}

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
		return nil, fmt.Errorf("not valid req host: '%s'", host)
	}

	if domain.Proxy == nil {
		return nil, fmt.Errorf("proxy field is empty for %s", host)
	}

	if domain.Proxy.Mode == "" {
		return nil, fmt.Errorf("proxy mode field is empty for %s", host)
	}

	return domain, nil
}

func notValidDomainFor(host string) (*models.Domain, error) {
	return nil, fmt.Errorf("not valid req host: '%s'", host)
}

func (t *Target) resolve(host, port string) error {
	var err error

	// by default each target has a 20 second cache
	t.CacheTimeout = time.Second * 20
	t.FetchedAt = time.Now()
	t.FetchedSource = "MongoDB"

	switch t.Proxy.Mode {
	case ModeMaintenance:
		t.URL, _ = url.Parse("http://localhost/maintenance")
	case ModeRedirect:
		t.URL, err = url.Parse(utils.CheckScheme(t.Proxy.FullUrl))
		if err != nil {
			return err
		}
	case ModeVM:
		t.URL, err = t.vm(host, port)
		if err != nil {
			return err
		}
	case ModeInternal:
		s := service{
			username:    t.Proxy.Username,
			servicename: t.Proxy.Servicename,
			build:       t.Proxy.Key,
		}

		t.URL, err = s.resolve()
		if err != nil {
			return err
		}
	default:
		return errors.New("no mode defined for target resolver")
	}

	return nil
}

// vm returns a target that is obtained via the jVMs collections. The
// returned target's url is static and is not going to change. It is usually
// in form of "arslan.kd.io" -> "10.56.12.12". The default cacheTimeout is set
// to 0 seconds, means it will be cached forever (because it uses an IP that
// never change.)
func (t *Target) vm(host, port string) (*url.URL, error) {
	if len(t.HostnameAlias) == 0 {
		return nil, fmt.Errorf("no hostnameAlias defined for host (vm): %s", host)
	}

	var hostname string

	switch t.Proxy.Mode {
	case "roundrobin": // equal weights
		index := getIndex(host) // gives 0 if not available
		N := float64(len(t.HostnameAlias))
		n := int(math.Mod(float64(index+1), N))
		hostname = t.HostnameAlias[n]

		addOrUpdateIndex(host, n)
	case "random":
		randomIndex := rand.Intn(len(t.HostnameAlias) - 1)
		hostname = t.HostnameAlias[randomIndex]
	default:
		hostname = t.HostnameAlias[0]
	}

	vm, err := modelhelper.GetVM(hostname)
	if err != nil {
		return nil, err
	}

	if vm.HostKite == "" || vm.IP == nil {
		t.Proxy.Mode = ModeVMOff
		return nil, errors.New("vm is off")
	}

	vmAddr := vm.IP.String()
	if !utils.HasPort(vmAddr) {
		vmAddr = utils.AddPort(vmAddr, port)
	}

	u, err := url.Parse("http://" + vmAddr)
	if err != nil {
		return nil, err
	}

	return u, nil
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
