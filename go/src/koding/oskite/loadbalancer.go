package oskite

import (
	"fmt"
	"koding/virt"
	"math/rand"
	"sort"
	"strings"
	"sync"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	redigo "github.com/garyburd/redigo/redis"
	"github.com/koding/redis"
)

var (
	oskites   = make(map[string]*OskiteInfo)
	oskitesMu sync.Mutex
)

func (o *Oskite) loadBalancer(correlationName, username, deadService string) string {
	blog := func(v interface{}) {
		log.Info("oskite loadbalancer for [correlationName: '%s' user: '%s' deadService: '%s'] results in --> %v.", correlationName, username, deadService, v)
	}
	// Ensure we are using a mongo master so that we can avoid db induced races
	mongodbConn.Session.SetSafe(&mgo.Safe{W: 3, WTimeout: 2, FSync: true})

	resultOskite := o.ServiceUniquename
	lowestOskite := lowestOskiteLoad()
	if lowestOskite != "" {
		if deadService == lowestOskite {
			resultOskite = o.ServiceUniquename
		} else {
			resultOskite = lowestOskite
		}
	}

	var vm *virt.VM
	if bson.IsObjectIdHex(correlationName) {
		mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.FindId(bson.ObjectIdHex(correlationName)).One(&vm)
		})
	}

	if vm == nil {
		if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Find(bson.M{"hostnameAlias": correlationName}).One(&vm)
		}); err != nil {
			blog(fmt.Sprintf("no hostnameAlias found, returning %s", resultOskite))
			return resultOskite // no vm was found, return this oskite
		}
	}

	if vm.PinnedToHost != "" {
		blog(fmt.Sprintf("returning pinnedHost '%s'", vm.PinnedToHost))
		return vm.PinnedToHost
	}

	if vm.HostKite == "" {
		// also set hoskite to prevent race condition between terminal and
		// oskite. Because if we set it now, the "kite.who" method of terminal
		// will not reply with an empty response.
		err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id, "hostKite": nil}, bson.M{"$set": bson.M{"hostKite": resultOskite}})
		})
		if err != nil {
			blog(fmt.Sprintf("hostkite is empty returning '%s' (update err: %s)", resultOskite, err))
		} else {
			blog(fmt.Sprintf("hostkite is empty returning '%s'", resultOskite))
		}
		return resultOskite
	}

	// maintenance and banned will be handled again in valideVM() function,
	// which will return a permission error.
	if vm.HostKite == "(maintenance)" || vm.HostKite == "(banned)" {
		blog(fmt.Sprintf("hostkite is %s returning '%s'", vm.HostKite, resultOskite))
		return resultOskite
	}

	// Set hostkite to nil if we detect a dead service. On the next call,
	// Oskite will point to an health service in validateVM function()
	// because it will detect that the hostkite is nil and change it to the
	// healthy service given by the client, which is the returned
	// k.ServiceUniqueName.
	if vm.HostKite == deadService {
		blog(fmt.Sprintf("dead service detected %s returning '%s'", vm.HostKite, o.ServiceUniquename))
		if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
			return c.Update(bson.M{"_id": vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
		}); err != nil {
			log.LogError(err, 0, vm.Id.Hex())
		}

		return resultOskite
	}

	blog(fmt.Sprintf("returning existing hostkite '%s'", vm.HostKite))
	return vm.HostKite
}

func (o *Oskite) setupRedis() {
	if o.RedisSession != nil {
		return
	}

	session, err := redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}

	o.RedisSession = session

	// oskite:production:sj:
	o.RedisPrefix = "oskite:" + conf.Environment + ":" + o.Region + ":"

	// kontainers-production-sj
	o.RedisKontainerSet = "kontainers-" + conf.Environment + "-" + o.Region

	// oskite:production:sj:kite-os-sj|kontainer3_sj_koding_com
	o.RedisKontainerKey = o.RedisPrefix + o.ServiceUniquename

	o.RedisSession.SetPrefix("oskite")
}

func (o *Oskite) redisBalancer() {
	o.setupRedis()

	log.Info("Connected to Redis with %s", o.RedisKontainerKey)
	_, err := redigo.Int(o.RedisSession.Do("SADD", o.RedisKontainerSet, o.RedisKontainerKey))
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}

	// update regularly our VMS info
	go func() {
		expireDuration := time.Second * 5
		for _ = range time.Tick(2 * time.Second) {
			oskiteInfo := o.GetOskiteInfo()

			if _, err := o.RedisSession.Do("HMSET", redigo.Args{o.RedisKontainerKey}.AddFlat(oskiteInfo)...); err != nil {
				log.Error("redis HMSET err: %v", err.Error())
			}

			reply, err := redigo.Int(o.RedisSession.Do("EXPIRE", o.RedisKontainerKey, expireDuration.Seconds()))
			if err != nil {
				log.Error("redis SET Expire %v. reply: %v err: %v", o.RedisKontainerKey, reply, err.Error())
			}
		}
	}()

	// get oskite statuses from others every 2 seconds
	for _ = range time.Tick(2 * time.Second) {
		kontainers, err := redigo.Strings(o.RedisSession.Do("SMEMBERS", o.RedisKontainerSet))
		if err != nil {
			log.Error("redis SMEMBER kontainers. err: %v", err.Error())
		}

		for _, kontainerHostname := range kontainers {
			// convert to o.ServiceUniquename format
			remoteOskite := strings.TrimPrefix(kontainerHostname, o.RedisPrefix)

			values, err := redigo.Values(o.RedisSession.Do("HGETALL", kontainerHostname))
			if err != nil {
				log.Error("redis HTGETALL %s. err: %v", kontainerHostname, err.Error())

				// kontainer might be dead, key gets than expired, continue with the next one

				oskitesMu.Lock()
				delete(oskites, remoteOskite)
				oskitesMu.Unlock()
				continue
			}

			// cleanup members from the map if the key expires. Usually that
			// might due a host who added itself to the kontainer set but then
			// just died or added a wrong set name. If the kontainer comes up
			// again we do add it below again.
			if len(values) == 0 {
				oskitesMu.Lock()
				delete(oskites, remoteOskite)
				oskitesMu.Unlock()
				continue
			}

			oskiteInfo := new(OskiteInfo)
			if err := redigo.ScanStruct(values, oskiteInfo); err != nil {
				log.Error("redis ScanStruct err: %v", err.Error())
			}

			oskitesMu.Lock()
			oskites[remoteOskite] = oskiteInfo
			oskitesMu.Unlock()
		}
	}
}

func lowestOskiteLoad() (serviceUniquename string) {
	oskitesMu.Lock()
	defer oskitesMu.Unlock()

	oskitesSlice := make([]*OskiteInfo, 0, len(oskites))

	for s, v := range oskites {
		v.ServiceUniquename = s
		oskitesSlice = append(oskitesSlice, v)
	}

	sort.Sort(ByVM(oskitesSlice))

	middle := len(oskitesSlice) / 2
	if middle == 0 {
		return ""
	}

	// return randomly one of the lowest
	l := oskitesSlice[rand.Intn(middle)]

	// also pick up the highest to log information
	h := oskitesSlice[len(oskitesSlice)-1]

	log.Info("oskite picked up as lowest load %s with %d VMs (highest was: %d / %s)",
		l.ServiceUniquename, l.ActiveVMs, h.ActiveVMs, h.ServiceUniquename)

	return l.ServiceUniquename
}
