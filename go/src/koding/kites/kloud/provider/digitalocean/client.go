package digitalocean

import (
	"errors"
	"fmt"
	do "koding/kites/kloud/api/digitalocean"
	"koding/kites/kloud/klientprovisioner"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"koding/kites/kloud/packer"
	"koding/kites/kloud/utils"
	"strconv"
	"sync"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/mitchellh/packer/builder/digitalocean"
)

type Client struct {
	*do.DigitalOcean
	Log  logging.Logger
	Push func(string, int, machinestate.State)

	Caching     bool
	CachePrefix string

	Redis       *redis.RedisSession
	RedisPrefix string

	sync.Once
}

// Build is building an image and creates a droplet based on that image. If the
// given snapshot/image exist it directly skips to creating the droplet. It
// acceps two string arguments, first one is the snapshotname, second one is
// the dropletName.
func (c *Client) Build(snapshotName, dropletName, username string) (*protocol.BuildResponse, error) {
	// needed because this is passed as `data` to packer.Provider
	c.Builder.SnapshotName = snapshotName

	var image digitalocean.Image
	var err error

	// check if snapshot image does exist
	c.Push(fmt.Sprintf("Fetching image %s", snapshotName), 10, machinestate.Building)
	image, err = c.Image(snapshotName)
	if err != nil {
		return nil, err
	}

	c.Push(fmt.Sprintf("Getting the droplet '%s' image '%d'",
		dropletName, image.Id), 15, machinestate.Building)
	dropletId, err := c.NewDroplet(dropletName, image.Id)
	if err != nil {
		return nil, err
	}

	// our droplet has now an IP adress, get it
	c.Push(fmt.Sprintf("Getting info about droplet"), 60, machinestate.Building)
	droplet, err := c.ShowDroplet(dropletId)
	if err != nil {
		return nil, err
	}

	return &protocol.BuildResponse{
		IpAddress:    droplet.IpAddress,
		InstanceName: dropletName, // we don't use droplet.Name because it might have the cached name
		InstanceId:   strconv.Itoa(droplet.Id),
	}, nil
}

// CreateImage creates an image using Packer. It uses digitalocean.Builder
// data. It returns the image info.
func (c *Client) CreateImage() (digitalocean.Image, error) {
	data, err := utils.TemplateData(c.Builder, klientprovisioner.RawData)
	if err != nil {
		return digitalocean.Image{}, err
	}

	provider := &packer.Provider{
		BuildName: "digitalocean",
		Data:      data,
	}

	// this is basically a "packer build template.json"
	if err := provider.Build(); err != nil {
		return digitalocean.Image{}, err
	}

	// return the image result
	return c.Image(c.Builder.SnapshotName)
}

func (c *Client) DropletId() (uint, error) {
	if c.Builder.DropletId == "" {
		return 0, errors.New("dropletId is not available")
	}

	dropletId := utils.ToUint(c.Builder.DropletId)
	if dropletId == 0 {
		return 0, fmt.Errorf("malformed data received %v. droplet Id must be an int.",
			c.Builder.DropletId)
	}

	return dropletId, nil
}

func (c *Client) Start() error {
	dropletId, err := c.DropletId()
	if err != nil {
		return err
	}

	c.Push("Starting machine", 10, machinestate.Starting)

	eventId, err := c.PowerOn(dropletId)
	if err != nil {
		return err
	}

	c.Push("Start message is being sent, waiting.", 30, machinestate.Starting)
	return c.WaitUntilReady(eventId, 30, 80, machinestate.Starting)
}

func (c *Client) Stop() error {
	c.Push("Stopping machine", 10, machinestate.Stopping)

	dropletId, err := c.DropletId()
	if err != nil {
		return err
	}

	eventId, err := c.Shutdown(dropletId)
	if err != nil {
		return err
	}

	c.Push("Stop message is being sent, waiting.", 30, machinestate.Stopping)
	return c.WaitUntilReady(eventId, 30, 80, machinestate.Stopping)
}

func (c *Client) Restart() error {
	c.Push("Rebooting machine", 10, machinestate.Rebooting)

	dropletId, err := c.DropletId()
	if err != nil {
		return err
	}

	eventId, err := c.Reboot(dropletId)
	if err != nil {
		return err
	}

	c.Push("Reboot message is being sent, waiting.", 30, machinestate.Rebooting)
	return c.WaitUntilReady(int(eventId), 30, 80, machinestate.Rebooting)
}

func (c *Client) Destroy() error {
	c.Push("Terminating machine", 10, machinestate.Terminating)

	dropletId, err := c.DropletId()
	if err != nil {
		return err
	}

	eventId, err := c.DestroyDroplet(dropletId)
	if err != nil {
		return err
	}

	c.Push("Terminating message is being sent, waiting.", 30, machinestate.Terminating)
	return c.WaitUntilReady(int(eventId), 50, 80, machinestate.Terminating)
}

func (c *Client) Info() (*protocol.InfoResponse, error) {
	dropletId, err := c.DropletId()
	if err != nil {
		return nil, err
	}

	droplet, err := c.ShowDroplet(dropletId)
	if err != nil {
		return nil, err
	}

	if statusToState(droplet.Status) == machinestate.Unknown {
		c.Log.Warning("Unknown digitalocean status: %s. This needs to be fixed.", droplet.Status)
	}

	return &protocol.InfoResponse{
		State: statusToState(droplet.Status),
		Name:  droplet.Name,
	}, nil
}

// WaitUntilReady checks the given state for the eventID and returns nil if the
// state has been reached. It returns an error if the given timeout has been
// reached, if another generic error is produced or if the event status is of
// type "ERROR".
func (c *Client) WaitUntilReady(eventId, from, to int, state machinestate.State) error {
	timeout := time.After(5 * time.Minute)
	for {
		select {
		case <-timeout:
			return errors.New("Timeout while waiting for droplet to become ready")
		case <-time.Tick(3 * time.Second):
			c.Push("Waiting for droplet to be ready", from, state)

			event, err := c.CheckEvent(eventId)
			if err != nil {
				return err
			}

			if event.Event.ActionStatus == "done" {
				c.Push("Waiting is done. Got a successfull result.", from, state)
				return nil
			}

			// the next steps percentage is 60, fake it until we got there
			if from < to {
				from += 2
			}
		}
	}
}

func (c *Client) NewDroplet(dropletName string, imageId uint) (dropletId uint, err error) {
	// The name of the public key on DO
	keys, err := c.Keys()
	if err != nil {
		return 0, err
	}

	var keyId uint
	keyId = keys.GetId(protocol.KeyName)
	if keyId == 0 {
		keyId, err = c.CreateKey(protocol.KeyName, protocol.PublicKey)
		if err != nil {
			return 0, err
		}
	}

	c.Push(fmt.Sprintf("Creating droplet %s", dropletName), 20, machinestate.Building)
	dropletInfo, err := c.CreateDroplet(dropletName, keyId, imageId)
	if err != nil {
		return 0, err
	}
	c.Builder.DropletId = strconv.Itoa(dropletInfo.Droplet.Id)

	defer func() {
		// return value of latest err, if there is no error just return lazily
		if err == nil {
			return
		}

		c.Log.Error("Creating droplet err: %s", err.Error())

		c.Push("Destroying droplet", 95, machinestate.Building)
		_, err := c.DestroyDroplet(uint(dropletInfo.Droplet.Id))
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/droplets/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, dropletInfo.Droplet.Id, c.Creds.ClientID, c.Creds.APIKey)

			c.Log.Error("Error cleaning up droplet. Please delete the droplet manually: %v", curlstr)
		}
	}()

	// Now we wait until it's ready, it takes approx. 50-70 seconds to finish,
	// but we also add a timeout  of five minutes to not let stuck it there
	// forever.
	if err := c.WaitUntilReady(dropletInfo.Droplet.EventId, 25, 59, machinestate.Building); err != nil {
		return 0, err
	}

	return uint(dropletInfo.Droplet.Id), nil
}

// statusToState converts a digitalocean status to a sensible
// machinestate.State format
func statusToState(status string) machinestate.State {
	switch status {
	case "active":
		return machinestate.Running
	case "off":
		return machinestate.Stopped
	case "new":
		return machinestate.Building
	case "archive":
		return machinestate.Terminated
	default:
		return machinestate.Unknown
	}
}
