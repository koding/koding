package digitalocean

import (
	"errors"
	"koding/kites/kloud/kloud/protocol"
	"math/rand"
	"strconv"
	"time"
)

var (
	ErrNoCachedDroplets         = errors.New("No cached machines available.")
	ErrCachedDropletWithWrongId = errors.New("Cached droplet has a wrong Id")
)

const (
	CacheMachinePrefix = "koding-cache"
)

// CreateCacheDroplet creates a new droplet with a key, after creating the
// machine one needs to rename the machine to use it. It returns the dropletIf
// of the created machine.
func (c *Client) CreateCachedDroplet(imageId uint) (uint, error) {
	timeStamp := strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	dropletName := CacheMachinePrefix + "-" + strconv.Itoa(int(imageId)) + "-" + timeStamp

	c.Log.Info("Creating a cached Droplet with name '%s' based on image id: %v",
		dropletName, imageId)
	dropletId, err := c.NewDroplet(dropletName, imageId)
	if err != nil {
		return 0, err
	}

	return dropletId, nil
}

func (c *Client) NumberOfCachedDroplets() (int, error) {
	droplets, err := c.Droplets()
	if err != nil {
		return 0, err
	}

	return droplets.Filter(CacheMachinePrefix).Len(), nil
}

// CachedDroplet returns a pre created and cached droplets id.
func (c *Client) CachedDroplet(dropletName string, imageId uint) (uint, error) {
	droplets, err := c.Droplets()
	if err != nil {
		return 0, err
	}

	c.Log.Debug("All droplets %#v", droplets)
	cachedDroplets := droplets.Filter(CacheMachinePrefix + "-" + strconv.Itoa(int(imageId)))
	c.Log.Debug("Cached droplets %#v", cachedDroplets)

	if cachedDroplets.Len() == 0 {
		return 0, ErrNoCachedDroplets
	}

	cachedDroplet := cachedDroplets[rand.Int()%len(cachedDroplets)]
	if cachedDroplet.ImageId != int(imageId) {
		return 0, ErrNoCachedDroplets
	}

	c.Log.Info("Renaming cached Droplet to name '%s'", dropletName)
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

	c.Log.Info("Returning a cached Droplet with name '%s' based on image id: %v",
		dropletName, imageId)
	dropletId, err := c.CachedDroplet(dropletName, imageId)
	if err == nil {
		return dropletId, nil
	}

	c.Log.Warning("Getting cached Droplet error: %s", err)

	if err == ErrNoCachedDroplets || err == ErrCachedDropletWithWrongId {
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

	return 0, errors.New("No droplet available. This is unexpected, an immediate fix is required.")
}
