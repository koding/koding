package digitalocean

import (
	"errors"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"time"
)

func (c *Client) InitializeCaching() error {
	if !c.CacheEnabled {
		return errors.New("Caching is disabled.")
	}

	c.Once.Do(func() {
		droplets, err := c.Droplets()
		if err != nil {
			return
		}

		// if there is already some cache machine do not crate new ones.
		// TODO: puth the previous droplets into the cache channel
		droplets = droplets.Filter("koding-cache-*")
		initialCapacity := c.CacheCapacity - len(droplets)

		c.CacheDroplets = make(chan *Droplet, c.CacheCapacity)
		for i := 0; i < initialCapacity; i++ {
			go func() {
				droplet, err := c.CreateCacheDroplet()
				if err != nil {
					c.Log.Error("filling cache channel: %s", err.Error())
				}

				c.PutCacheDroplet(droplet)
			}()
		}
	})

	return nil
}

func (c *Client) CreateCacheDroplet() (*Droplet, error) {
	image, err := c.Image(protocol.DefaultImageName)
	if err != nil {
		return nil, err
	}

	dropletName := "koding-cache-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	droplet, err := c.DropletWithKey(dropletName, image.Id)
	if err != nil {
		return nil, err
	}

	return droplet, nil

}

func (c *Client) PutCacheDroplet(droplet *Droplet) error {
	select {
	case c.CacheDroplets <- droplet:
		return nil
	default:
		go c.DestroyDroplet(uint(droplet.Droplet.Id))
		return errors.New("cache is already full, deletin previous droplet")
	}
}

func (c *Client) GetCachedDroplet() (*Droplet, error) {
	select {
	case droplet := <-c.CacheDroplets:
		if droplet == nil {
			return nil, errors.New("pool is closed")
		}

		return droplet, nil
	default:
		return c.CreateCacheDroplet()
	}
}
