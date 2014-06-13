package digitalocean

import (
	"errors"
	"fmt"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"strings"
	"time"

	"github.com/garyburd/redigo/redis"
)

var (
	ErrNoCachedDroplets     = errors.New("No cached machines available.")
	ErrCachedDropletInvalid = errors.New("Cached machine has an invalid status.")
)

const (
	CacheMachinePrefix = "koding-cache"
	CacheRedisSetName  = "digitalocean"
)

// UpdateCachedDroplets is syncronizing the cached Droplets with Redis
func (c *Client) UpdateCachedDroplets(imageId uint) error {
	droplets, err := c.Droplets()
	if err != nil {
		return err
	}

	cachedDroplets := droplets.Filter(CacheMachinePrefix + "-" + strconv.Itoa(int(imageId)))
	c.Log.Info("Found %d cached droplets. Updating data with redis", cachedDroplets.Len())

	dropletIds := make([]interface{}, 0)
	for _, droplet := range cachedDroplets {
		dropletIds = append(dropletIds, droplet.Id)
	}

	// empty the set if nothing is found.
	if len(dropletIds) == 0 {
		if _, err := c.Redis.Del(CacheRedisSetName); err != nil {
			c.Log.Error("Adding updated cached droplets err: %v", err.Error())
		}

		return nil
	}

	c.Redis.Send("MULTI")
	c.Redis.Send("DEL", c.Redis.AddPrefix(CacheRedisSetName))
	c.Redis.Send("SADD", redis.Args{c.Redis.AddPrefix(CacheRedisSetName)}.Add(dropletIds...)...)
	_, err = c.Redis.Do("EXEC")
	return err
}

// CreateCacheDroplet creates a new droplet with a key, after creating the
// machine one needs to rename the machine to use it. It returns the dropletIf
// of the created machine.
func (c *Client) CreateCachedDroplet(imageId uint) error {
	timeStamp := strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	dropletName := CacheMachinePrefix + "-" + strconv.Itoa(int(imageId)) + "-" + timeStamp

	c.Log.Info("Creating a cached Droplet with name '%s' based on image id: %v",
		dropletName, imageId)
	dropletId, err := c.NewDroplet(dropletName, imageId)
	if err != nil {
		return err
	}

	if _, err := c.Redis.AddSetMembers(CacheRedisSetName, dropletId); err != nil {
		return err
	}

	return nil
}

// CachedDroplet returns a pre created and cached droplets id.
func (c *Client) CachedDroplet(dropletName string, imageId uint) (uint, error) {
	reply, err := c.Redis.PopSetMember(CacheRedisSetName)
	if err == redis.ErrNil {
		return 0, ErrNoCachedDroplets
	}

	if err != nil {
		return 0, err
	}

	dropletId, err := strconv.Atoi(reply)
	if err != nil {
		return 0, err
	}
	c.Log.Info("Fetched cached Droplet id %v", dropletId)

	// also test if the given dropletId is still existing in digitalOcean
	c.Log.Info("Checking if droplet '%v' is valid.", dropletId)
	cachedDroplet, err := c.ShowDroplet(uint(dropletId))
	if err != nil {
		return 0, err
	}
	fmt.Printf("cachedDroplet %+v\n", cachedDroplet)

	if statusToState(cachedDroplet.Status) != machinestate.Running {
		c.Log.Info("Cached droplet is not active, current status: '%s'", cachedDroplet.Status)
		return 0, ErrCachedDropletInvalid
	}

	cacheName := CacheMachinePrefix + "-" + strconv.Itoa(int(imageId))
	if !strings.Contains(cachedDroplet.Name, cacheName) {
		return 0, fmt.Errorf("Found a cached droplet, but name seems to be wrong. Expecting %s, got %s",
			cacheName, cachedDroplet.Name)
	}

	c.Log.Info("Renaming cached Droplet from '%s' to name '%s'", cachedDroplet.Name, dropletName)
	go c.RenameDroplet(uint(cachedDroplet.Id), dropletName)

	return uint(cachedDroplet.Id), nil
}

func (c *Client) GetDroplet(dropletName string, imageId uint) (uint, error) {
	if !c.Caching {
		c.Log.Info("Creating a new Droplet with name '%s' based on image id: %v",
			dropletName, imageId)
		return c.NewDroplet(dropletName, imageId)
	}

	c.Log.Info("Trying to find a cached Droplet based on image id: %v", imageId)
	dropletId, err := c.CachedDroplet(dropletName, imageId)
	if err == nil {
		return dropletId, nil
	}

	if err == ErrNoCachedDroplets || err == ErrCachedDropletInvalid {
		c.Log.Info("No cached Droplets are available for image id: %v", imageId)
		// TODO: for now just create one whenever we got one in the backend, we
		// will handle this dynamically in the future
		go func() {
			image, err := c.Image(protocol.DefaultImageName)
			if err != nil {
				c.Log.Error("couldn't get image information for %s, err: %s",
					protocol.DefaultImageName, err)
				return
			}

			c.CreateCachedDroplet(image.Id)
		}()

		// Create a new one and return.
		return c.NewDroplet(dropletName, imageId)
	}

	c.Log.Warning("This is unexpected, an immediate fix is required: %s", err)
	return c.NewDroplet(dropletName, imageId)
}
