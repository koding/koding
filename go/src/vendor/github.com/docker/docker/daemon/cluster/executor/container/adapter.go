package container

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"syscall"
	"time"

	"github.com/Sirupsen/logrus"
	"github.com/docker/docker/api/server/httputils"
	executorpkg "github.com/docker/docker/daemon/cluster/executor"
	"github.com/docker/engine-api/types"
	"github.com/docker/engine-api/types/events"
	"github.com/docker/engine-api/types/versions"
	"github.com/docker/libnetwork"
	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/log"
	"golang.org/x/net/context"
)

// containerAdapter conducts remote operations for a container. All calls
// are mostly naked calls to the client API, seeded with information from
// containerConfig.
type containerAdapter struct {
	backend   executorpkg.Backend
	container *containerConfig
}

func newContainerAdapter(b executorpkg.Backend, task *api.Task) (*containerAdapter, error) {
	ctnr, err := newContainerConfig(task)
	if err != nil {
		return nil, err
	}

	return &containerAdapter{
		container: ctnr,
		backend:   b,
	}, nil
}

func (c *containerAdapter) pullImage(ctx context.Context) error {
	spec := c.container.spec()

	// if the image needs to be pulled, the auth config will be retrieved and updated
	var encodedAuthConfig string
	if spec.PullOptions != nil {
		encodedAuthConfig = spec.PullOptions.RegistryAuth
	}

	authConfig := &types.AuthConfig{}
	if encodedAuthConfig != "" {
		if err := json.NewDecoder(base64.NewDecoder(base64.URLEncoding, strings.NewReader(encodedAuthConfig))).Decode(authConfig); err != nil {
			logrus.Warnf("invalid authconfig: %v", err)
		}
	}

	pr, pw := io.Pipe()
	metaHeaders := map[string][]string{}
	go func() {
		err := c.backend.PullImage(ctx, c.container.image(), "", metaHeaders, authConfig, pw)
		pw.CloseWithError(err)
	}()

	dec := json.NewDecoder(pr)
	m := map[string]interface{}{}
	for {
		if err := dec.Decode(&m); err != nil {
			if err == io.EOF {
				break
			}
			return err
		}
		// TODO(stevvooe): Report this status somewhere.
		logrus.Debugln("pull progress", m)
	}
	// if the final stream object contained an error, return it
	if errMsg, ok := m["error"]; ok {
		return fmt.Errorf("%v", errMsg)
	}
	return nil
}

func (c *containerAdapter) createNetworks(ctx context.Context) error {
	for _, network := range c.container.networks() {
		ncr, err := c.container.networkCreateRequest(network)
		if err != nil {
			return err
		}

		if err := c.backend.CreateManagedNetwork(ncr); err != nil { // todo name missing
			if _, ok := err.(libnetwork.NetworkNameError); ok {
				continue
			}

			return err
		}
	}

	return nil
}

func (c *containerAdapter) removeNetworks(ctx context.Context) error {
	for _, nid := range c.container.networks() {
		if err := c.backend.DeleteManagedNetwork(nid); err != nil {
			if _, ok := err.(*libnetwork.ActiveEndpointsError); ok {
				continue
			}
			log.G(ctx).Errorf("network %s remove failed: %v", nid, err)
			return err
		}
	}

	return nil
}

func (c *containerAdapter) create(ctx context.Context, backend executorpkg.Backend) error {
	var cr types.ContainerCreateResponse
	var err error
	version := httputils.VersionFromContext(ctx)
	validateHostname := versions.GreaterThanOrEqualTo(version, "1.24")

	if cr, err = backend.CreateManagedContainer(types.ContainerCreateConfig{
		Name:       c.container.name(),
		Config:     c.container.config(),
		HostConfig: c.container.hostConfig(),
		// Use the first network in container create
		NetworkingConfig: c.container.createNetworkingConfig(),
	}, validateHostname); err != nil {
		return err
	}

	// Docker daemon currently doesn't support multiple networks in container create
	// Connect to all other networks
	nc := c.container.connectNetworkingConfig()

	if nc != nil {
		for n, ep := range nc.EndpointsConfig {
			if err := backend.ConnectContainerToNetwork(cr.ID, n, ep); err != nil {
				return err
			}
		}
	}

	if err := backend.UpdateContainerServiceConfig(cr.ID, c.container.serviceConfig()); err != nil {
		return err
	}

	return nil
}

func (c *containerAdapter) start(ctx context.Context) error {
	version := httputils.VersionFromContext(ctx)
	validateHostname := versions.GreaterThanOrEqualTo(version, "1.24")
	return c.backend.ContainerStart(c.container.name(), nil, validateHostname)
}

func (c *containerAdapter) inspect(ctx context.Context) (types.ContainerJSON, error) {
	cs, err := c.backend.ContainerInspectCurrent(c.container.name(), false)
	if ctx.Err() != nil {
		return types.ContainerJSON{}, ctx.Err()
	}
	if err != nil {
		return types.ContainerJSON{}, err
	}
	return *cs, nil
}

// events issues a call to the events API and returns a channel with all
// events. The stream of events can be shutdown by cancelling the context.
func (c *containerAdapter) events(ctx context.Context) <-chan events.Message {
	log.G(ctx).Debugf("waiting on events")
	buffer, l := c.backend.SubscribeToEvents(time.Time{}, time.Time{}, c.container.eventFilter())
	eventsq := make(chan events.Message, len(buffer))

	for _, event := range buffer {
		eventsq <- event
	}

	go func() {
		defer c.backend.UnsubscribeFromEvents(l)

		for {
			select {
			case ev := <-l:
				jev, ok := ev.(events.Message)
				if !ok {
					log.G(ctx).Warnf("unexpected event message: %q", ev)
					continue
				}
				select {
				case eventsq <- jev:
				case <-ctx.Done():
					return
				}
			case <-ctx.Done():
				return
			}
		}
	}()

	return eventsq
}

func (c *containerAdapter) wait(ctx context.Context) error {
	return c.backend.ContainerWaitWithContext(ctx, c.container.name())
}

func (c *containerAdapter) shutdown(ctx context.Context) error {
	// Default stop grace period to 10s.
	stopgrace := 10
	spec := c.container.spec()
	if spec.StopGracePeriod != nil {
		stopgrace = int(spec.StopGracePeriod.Seconds)
	}
	return c.backend.ContainerStop(c.container.name(), stopgrace)
}

func (c *containerAdapter) terminate(ctx context.Context) error {
	return c.backend.ContainerKill(c.container.name(), uint64(syscall.SIGKILL))
}

func (c *containerAdapter) remove(ctx context.Context) error {
	return c.backend.ContainerRm(c.container.name(), &types.ContainerRmConfig{
		RemoveVolume: true,
		ForceRemove:  true,
	})
}

func (c *containerAdapter) createVolumes(ctx context.Context, backend executorpkg.Backend) error {
	// Create plugin volumes that are embedded inside a Mount
	for _, mount := range c.container.task.Spec.GetContainer().Mounts {
		if mount.Type != api.MountTypeVolume {
			continue
		}

		if mount.VolumeOptions == nil {
			continue
		}

		if mount.VolumeOptions.DriverConfig == nil {
			continue
		}

		req := c.container.volumeCreateRequest(&mount)

		// Check if this volume exists on the engine
		if _, err := backend.VolumeCreate(req.Name, req.Driver, req.DriverOpts, req.Labels); err != nil {
			// TODO(amitshukla): Today, volume create through the engine api does not return an error
			// when the named volume with the same parameters already exists.
			// It returns an error if the driver name is different - that is a valid error
			return err
		}

	}

	return nil
}

// todo: typed/wrapped errors
func isContainerCreateNameConflict(err error) bool {
	return strings.Contains(err.Error(), "Conflict. The name")
}

func isUnknownContainer(err error) bool {
	return strings.Contains(err.Error(), "No such container:")
}

func isStoppedContainer(err error) bool {
	return strings.Contains(err.Error(), "is already stopped")
}
