package digitalocean

import (
	"fmt"
	"koding/kites/kloud/sshutil"
	"strconv"

	"github.com/mitchellh/packer/builder/digitalocean"
)

var dropletCache = make(chan uint, 10)

type CachedMachine struct {
	Droplet    *Droplet
	PrivateKey string
	KeyId      uint
}

func (d *DigitalOcean) DropletWithKey(dropletName string, imageId uint) (c *CachedMachine, err error) {
	// create temporary key to deploy user based key
	d.Push(fmt.Sprintf("Creating temporary ssh key"), 15)
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// The name of the public key on DO
	keyName := fmt.Sprintf("koding-%s", dropletName)
	d.Log.Debug("Creating key with name '%s'", keyName)
	keyId, err := d.CreateKey(keyName, publicKey)
	if err != nil {
		return nil, err
	}

	defer func() {
		// return value of latest err, if there is no error just return lazily
		if err == nil {
			return
		}

		d.Push("Destroying temporary droplet key", 95)
		err := d.DestroyKey(keyId) // remove after we are done
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/ssh_keys/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, keyId, d.Creds.ClientID, d.Creds.APIKey)

			d.Push(fmt.Sprintf("Error cleaning up ssh key. Please delete the key manually: %v", curlstr), 95)
		}
	}()

	d.Push(fmt.Sprintf("Creating droplet %s", dropletName), 20)
	dropletInfo, err := d.CreateDroplet(dropletName, keyId, imageId)
	if err != nil {
		return nil, err
	}
	d.Builder.DropletId = strconv.Itoa(dropletInfo.Droplet.Id)

	defer func() {
		// return value of latest err, if there is no error just return lazily
		if err == nil {
			return
		}

		d.Push("Destroying droplet", 95)
		err := d.DestroyDroplet(uint(dropletInfo.Droplet.Id))
		if err != nil {
			curlstr := fmt.Sprintf("curl '%v/droplets/%v/destroy?client_id=%v&api_key=%v'",
				digitalocean.DIGITALOCEAN_API_URL, dropletInfo.Droplet.Id, d.Creds.ClientID, d.Creds.APIKey)

			d.Push(fmt.Sprintf("Error cleaning up droplet. Please delete the droplet manually: %v", curlstr), 95)
		}
	}()

	// Now we wait until it's ready, it takes approx. 50-70 seconds to finish,
	// but we also add a timeout  of five minutes to not let stuck it there
	// forever.
	if err := d.WaitUntilReady(dropletInfo.Droplet.EventId, 25, 59); err != nil {
		return nil, err
	}

	// our droplet has now an IP adress, get it
	d.Push(fmt.Sprintf("Getting info about droplet"), 60)
	droplet, err := d.DropletInfo(uint(dropletInfo.Droplet.Id))
	if err != nil {
		return nil, err
	}

	return &CachedMachine{
		Droplet:    droplet,
		PrivateKey: privateKey,
		KeyId:      keyId,
	}, nil
}
