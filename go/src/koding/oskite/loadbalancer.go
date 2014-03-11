package oskite

import (
	"koding/databases/redis"
	"math/rand"
	"sort"
	"strings"
	"sync"
	"time"
	redigo "github.com/garyburd/redigo/redis"
)

var (
	oskites   = make(map[string]*OskiteInfo)
	oskitesMu sync.Mutex
)

func (o *Oskite) redisBalancer() {
	session, err := redis.NewRedisSession(conf.Redis)
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}
	session.SetPrefix("oskite")

	prefix := "oskite:" + conf.Environment + ":"
	kontainerSet := "kontainers-" + conf.Environment

	log.Info("Connected to Redis with %s", prefix+o.ServiceUniquename)

	_, err = redigo.Int(session.Do("SADD", kontainerSet, prefix+o.ServiceUniquename))
	if err != nil {
		log.Error("redis SADD kontainers. err: %v", err.Error())
	}

	// update regularly our VMS info
	go func() {
		expireDuration := time.Second * 5
		for _ = range time.Tick(2 * time.Second) {
			key := prefix + o.ServiceUniquename
			oskiteInfo := o.GetOskiteInfo()

			if _, err := session.Do("HMSET", redigo.Args{key}.AddFlat(oskiteInfo)...); err != nil {
				log.Error("redis HMSET err: %v", err.Error())
			}

			reply, err := redigo.Int(session.Do("EXPIRE", key, expireDuration.Seconds()))
			if err != nil {
				log.Error("redis SET Expire %v. reply: %v err: %v", key, reply, err.Error())
			}
		}
	}()

	// get oskite statuses from others every 2 seconds
	for _ = range time.Tick(2 * time.Second) {
		kontainers, err := redigo.Strings(session.Do("SMEMBERS", kontainerSet))
		if err != nil {
			log.Error("redis SMEMBER kontainers. err: %v", err.Error())
		}

		for _, kontainerHostname := range kontainers {
			// convert to o.ServiceUniquename formst
			remoteOskite := strings.TrimPrefix(kontainerHostname, prefix)

			values, err := redigo.Values(session.Do("HGETALL", kontainerHostname))
			if err != nil {
				log.Error("redis HTGETALL %s. err: %v", kontainerHostname, err.Error())

				// kontainer might be dead, key gets than expired, continue with the next one

				oskitesMu.Lock()
				delete(oskites, remoteOskite)
				oskitesMu.Unlock()
				continue
			}

			oskiteInfo := new(OskiteInfo)
			if err := redigo.ScanStruct(values, oskiteInfo); err != nil {
				log.Error("redis ScanStruct err: %v", err.Error())
			}

			log.Debug("%s: %+v", kontainerHostname, oskiteInfo)

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
