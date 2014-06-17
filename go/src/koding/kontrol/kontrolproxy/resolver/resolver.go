package resolver

import (
	"container/ring"
	"errors"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kontrol/kontrolproxy/utils"
	"log"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"sync"
	"time"
)

var (
	ErrGone       = errors.New("target is gone")
	ErrNoHost     = errors.New("no healthy hostname available")
	ErrVMOff      = errors.New("vm is off")
	ErrVMNotFound = errors.New("vm not found")

	// cache lookup tables
	targets   = make(map[string]*Target)
	targetsMu sync.Mutex // protects targets map

	// our load balancer roundrobin maps. Key is created for each index key.
	rings   = make(map[string]*RoundRing)
	ringsMu sync.Mutex
)

const (
	CookieBuildName  = "kdproxy-preferred-build"
	CookieDomainName = "kdproxy-preferred-domain"

	ModeMaintenance = "maintenance"
	ModeInternal    = "internal"
	ModeVM          = "vm"
	ModeRedirect    = "redirect"

	HealthCheckInterval = time.Second * 10
)

// Target is returned for every incoming request host.
type Target struct {
	// URL contains the final target
	URL *url.URL

	// Contains errors specific for the given mode. For example if the mode is
	// "vm" and the vm is off, this field will be set to: "ErrVMOff"
	Err error

	// A list of hosts, mainly used for vm mode
	HostnameAlias []string

	// Length of given hosts or hostnamealis
	Length int

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

	// HostCacheDisabled is used to disable caching host based targets.
	HostCacheDisabled bool

	// To store additional data about target
	Properties map[string]interface{}
}

// GetTarget is used to get the target according to the incoming request it
// looks if a request has set cookies to change the target. If not it
// fallbacks to request host data.
func GetTarget(req *http.Request) (*Target, error) {
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

// TargetByHost is used to resolve any hostname to their final target
// destination together with the mode of the domain for the given host string.
// Any incoming domain can have multiple different target destinations.
// TargetByHost returns the ultimate target destinations. Some examples:
//
// koding.com -> "http://webserver-build-koding-813a.in.koding.com:3000", mode:internal
// arslan.kd.io -> "http://10.128.2.25:80", mode:vm
// y.koding.com -> "http://localhost/maintenance", mode:maintenance
func TargetByHost(host string) (*Target, error) {
	target, err := getFromCache(host)
	if err == nil {
		return target, nil
	}

	return getFromDB(host)
}

func getFromCache(host string) (*Target, error) {
	targetsMu.Lock()
	defer targetsMu.Unlock()

	target, ok := targets[host]
	if !ok {
		return nil, fmt.Errorf("target not found for %s", host)
	}

	if target.HostCacheDisabled {
		target.FetchedSource = "InternalCache"
		return target, nil
	}

	if time.Now().Before(target.FetchedAt.Add(target.CacheTimeout)) {
		target.FetchedSource = "Cache"
		return target, nil
	}

	// invalidate and delete from cache
	delete(targets, host)

	// only internal mode uses ring cache
	if target.Proxy.Mode == ModeInternal {
		ringKey := target.GetService().String()

		ringsMu.Lock()
		round, ok := rings[ringKey]
		if ok {
			round.ticker.Stop()
		}
		round = nil

		delete(rings, ringKey)
		ringsMu.Unlock()
	}

	return nil, fmt.Errorf("target cache invalidation for host %s", host)
}

func getFromDB(host string) (*Target, error) {
	targetsMu.Lock()
	defer targetsMu.Unlock()

	domain, err := getDomain(host)
	if err != nil {
		return nil, err
	}

	target := &Target{
		Proxy:         domain.Proxy,
		HostnameAlias: domain.HostnameAlias,
		CacheTimeout:  time.Second * 10,
		FetchedAt:     time.Now(),
		FetchedSource: "MongoDB",
		Properties:    make(map[string]interface{}),
	}

	err = target.Resolve(host)
	if err != nil {
		return nil, err
	}

	targets[host] = target

	return target, nil
}

func getDomain(host string) (*models.Domain, error) {
	// remove port if host as a port
	if utils.HasPort(host) {
		host, _, _ = net.SplitHostPort(host)
	}

	domain := new(models.Domain)
	var err error

	domain, err = modelhelper.GetDomain(host)
	if err != nil {
		return nil, fmt.Errorf("not found in DB '%s'", host)
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

func (t *Target) Resolve(host string) error {
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

	switch t.Proxy.Mode {
	case ModeMaintenance:
		t.URL, _ = url.Parse("http://localhost/maintenance")
	case ModeRedirect:
		t.URL, t.Err = url.Parse(utils.CheckScheme(t.Proxy.FullUrl))
	case ModeVM:
		t.URL, t.Err = t.resolveVM(host, port)
	case ModeInternal:
		t.CacheTimeout = time.Second * 60
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
func (t *Target) resolveVM(host, port string) (*url.URL, error) {
	if len(t.HostnameAlias) == 0 {
		return nil, fmt.Errorf("no hostnameAlias defined for host (vm): %s", host)
	}

	hostname := t.HostnameAlias[0]
	vm, err := modelhelper.GetVM(hostname)
	if err != nil {
		return nil, ErrVMNotFound
	}

	t.Properties["hostkite"] = vm.HostKite
	t.Properties["alwaysOn"] = vm.AlwaysOn
	t.Properties["disableSecurePage"] = vm.DisableSecurePage

	if vm.HostKite == "" || vm.IP == nil {
		return nil, ErrVMOff
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

func (t *Target) GetService() *Service {
	return &Service{
		Username:    t.Proxy.Username,
		Servicename: t.Proxy.Servicename,
		Build:       t.Proxy.Key,
	}
}

type Service struct {
	Username    string
	Servicename string
	Build       string
	Length      int
}

func (s *Service) String() string {
	return fmt.Sprintf("%s-%s-%s", s.Username, s.Servicename, s.Build)
}

// NextRoundRing returns a roundRing that is obtained via the jProxyServices
// collection, which is used for internal services. An example service to
// target could be in form: "koding, server, 950" ->
// "webserver-950.sj.koding.com:3000".
func (s *Service) NextRoundRing() (*RoundRing, error) {
	ringsMu.Lock()
	defer ringsMu.Unlock()

	indexkey := s.String()
	r, ok := rings[indexkey]
	if !ok {
		// get the hosts to be roundrobined
		hosts, err := s.serviceHosts()
		if err != nil {
			return nil, err
		}

		r = &RoundRing{
			Ring: newRing(checkHosts(hosts)),
		}
		rings[indexkey] = r

		s.Length = r.Ring.Len()

		// start health checker for base hosts
		go r.healtChecker(hosts, indexkey)
	}

	// means the healtChecker created a zero length ring. This is caused only
	// when all hosts are sick.
	if r.Ring == nil {
		return nil, errors.New("all servers are down")
	}

	r.Ring = r.Ring.Next()
	rings[indexkey] = r

	return r.Copy(), nil
}

// buildHosts returns a list of target hosts for the given build parameters.
func (s *Service) serviceHosts() ([]string, error) {
	latestKey := modelhelper.GetLatestKey(s.Username, s.Servicename)
	if latestKey == "" {
		latestKey = s.Build
	}

	keyData, err := modelhelper.GetKey(s.Username, s.Servicename, s.Build)
	if err != nil {
		currentVersion, _ := strconv.Atoi(s.Build)
		latestVersion, _ := strconv.Atoi(latestKey)
		if currentVersion < latestVersion {
			return nil, ErrGone
		} else {
			return nil, fmt.Errorf("no keyData for username '%s', servicename '%s' and key '%s'",
				s.Username, s.Servicename, s.Build)
		}
	}

	if !keyData.Enabled {
		return nil, errors.New("host is not allowed to be used")
	}

	return keyData.Host, nil
}

type RoundRing struct {
	Ring   *ring.Ring
	ticker *time.Ticker
}

func (r *RoundRing) Copy() *RoundRing {
	n := new(RoundRing)
	*n = *r
	return n
}

func (r *RoundRing) Director(req *http.Request) error {
	value, ok := r.Ring.Value.(string)
	if !ok {
		return fmt.Errorf("ring value is not string: %+v", value)
	}
	r.Ring = r.Ring.Next()

	// be sure that the backendServer has scheme prependend
	backendServer := utils.CheckScheme(value)
	targetURL, err := url.Parse(backendServer)
	if err != nil {
		return err
	}

	if !utils.HasPort(targetURL.Host) {
		req.URL.Host = utils.AddPort(targetURL.Host, "80")
	} else {
		req.URL.Host = targetURL.Host
	}

	req.URL.Scheme = targetURL.Scheme

	return nil
}

func (r *RoundRing) healtChecker(hosts []string, indexkey string) {
	r.ticker = time.NewTicker(HealthCheckInterval)

	for _ = range r.ticker.C {
		healtyHosts := checkHosts(hosts)
		// replace hosts with healthy ones
		r.Ring = newRing(healtyHosts)
	}
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

// CleanCache cleans the cache for the given host
func CleanCache(host string) {
	targetsMu.Lock()
	target, ok := targets[host]
	if !ok {
		targetsMu.Unlock()
		return
	}
	delete(targets, host)
	targetsMu.Unlock()

	// only internal mode uses ring cache
	if target.Proxy.Mode == ModeInternal {
		ringKey := target.GetService().String()
		fmt.Println("cleaning also ", ringKey)

		ringsMu.Lock()
		round, ok := rings[ringKey]
		if ok {
			fmt.Println("stopping ticker")
			round.ticker.Stop()
		}
		delete(rings, ringKey)
		ringsMu.Unlock()
	}
}

// checkHosts checks each host for the given hosts slice and returns a new
// slice with healthy/alive ones.
func checkHosts(hosts []string) []string {
	healthyHosts := make([]string, 0)
	var mu sync.Mutex // protects healtyHosts
	var wg sync.WaitGroup

	for _, host := range hosts {
		wg.Add(1)
		go func(host string) {
			err := utils.CheckServer(host)
			if err != nil {
				log.Printf("server '%s' is sick. Removing it from the healty server pool. err: %s\n", host, err)
			} else {
				mu.Lock()
				healthyHosts = append(healthyHosts, host)
				mu.Unlock()
			}

			wg.Done()
		}(host)
	}

	wg.Wait()

	log.Println("alive hosts", healthyHosts)
	return healthyHosts
}
