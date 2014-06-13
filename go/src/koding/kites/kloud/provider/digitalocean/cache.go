package digitalocean

import (
	"errors"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"time"

	"github.com/garyburd/redigo/redis"
)

var (
	ErrNoCachedDroplets = errors.New("No cached machines available.")
)

const (
	CacheMachinePrefix = "koding-cache"
	CacheRedisSetName  = "digitalocean"
)

func (c *Client) UpdateCachedDroplets(imageId uint) error {
	droplets, err := c.Droplets()
	if err != nil {
		return err
	}

	cachedDroplets := droplets.Filter(CacheMachinePrefix + "-" + strconv.Itoa(int(imageId)))
	c.Log.Info("Found %d cached droplets. Updating data with redis", cachedDroplets.Len())

	for _, droplet := range cachedDroplets {
		if _, err := c.Redis.AddSetMembers(CacheRedisSetName, droplet.Id); err != nil {
			c.Log.Error("Adding updated cached droplets err: %v", err.Error())
		}
	}

	return nil
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
func (c *Client) CachedDroplet(dropletName string, imageId uint) (u uint, err error) {
	reply, err := c.Redis.PopSetMember(CacheRedisSetName)
	if err == redis.ErrNil {
		return 0, ErrNoCachedDroplets
	}

	if err != nil {
		return 0, err
	}

	// add back the dropletId to the set if something goes wrong
	defer func() {
		if err != nil {
			if _, err := c.Redis.AddSetMembers(CacheRedisSetName, reply); err != nil {
				c.Log.Error("cachedDroplet: adding back set key: %s", err.Error())
			}
		}
	}()

	dropletId, err := strconv.Atoi(reply)
	if err != nil {
		return 0, err
	}
	c.Log.Info("Fetched cached Droplet id %v", dropletId)

	// also test if the given dropletId is still existing in digitalOcean
	cachedDroplet, err := c.ShowDroplet(uint(dropletId))
	if err != nil {
		return 0, err
	}

	c.Log.Info("Renaming cached Droplet from '%s' to name '%s'", cachedDroplet.Name, dropletName)
	_, err = c.RenameDroplet(uint(cachedDroplet.Id), dropletName)
	if err != nil {
		return 0, err
	}

	return uint(cachedDroplet.Id), nil
}

func (c *Client) GetDroplet(dropletName string, imageId uint) (uint, error) {
	if !c.Caching {
		c.Log.Info("Creating a new Droplet with name '%s' based on image id: %v",
			dropletName, imageId)
		return c.NewDroplet(dropletName, imageId)
	}

	c.Once.Do(func() {
		go c.UpdateCachedDroplets(imageId)
	})

	c.Log.Info("Trying to find a cached Droplet based on image id: %v", imageId)
	dropletId, err := c.CachedDroplet(dropletName, imageId)
	if err == nil {
		return dropletId, nil
	}

	if err == ErrNoCachedDroplets {
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
