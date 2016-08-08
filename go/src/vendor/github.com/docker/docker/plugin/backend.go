// +build experimental

package plugin

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"

	"github.com/Sirupsen/logrus"
	"github.com/docker/docker/pkg/archive"
	"github.com/docker/docker/pkg/stringid"
	"github.com/docker/docker/plugin/distribution"
	"github.com/docker/docker/reference"
	"github.com/docker/engine-api/types"
)

// Disable deactivates a plugin, which implies that they cannot be used by containers.
func (pm *Manager) Disable(name string) error {
	p, err := pm.get(name)
	if err != nil {
		return err
	}
	return pm.disable(p)
}

// Enable activates a plugin, which implies that they are ready to be used by containers.
func (pm *Manager) Enable(name string) error {
	p, err := pm.get(name)
	if err != nil {
		return err
	}
	return pm.enable(p)
}

// Inspect examines a plugin manifest
func (pm *Manager) Inspect(name string) (tp types.Plugin, err error) {
	p, err := pm.get(name)
	if err != nil {
		return tp, err
	}
	return p.P, nil
}

// Pull pulls a plugin and enables it.
func (pm *Manager) Pull(name string, metaHeader http.Header, authConfig *types.AuthConfig) (types.PluginPrivileges, error) {
	ref, err := reference.ParseNamed(name)
	if err != nil {
		logrus.Debugf("error in reference.ParseNamed: %v", err)
		return nil, err
	}
	name = ref.String()

	if p, _ := pm.get(name); p != nil {
		logrus.Debugf("plugin already exists")
		return nil, fmt.Errorf("%s exists", name)
	}

	pluginID := stringid.GenerateNonCryptoID()

	if err := os.MkdirAll(filepath.Join(pm.libRoot, pluginID), 0755); err != nil {
		logrus.Debugf("error in MkdirAll: %v", err)
		return nil, err
	}

	pd, err := distribution.Pull(name, pm.registryService, metaHeader, authConfig)
	if err != nil {
		logrus.Debugf("error in distribution.Pull(): %v", err)
		return nil, err
	}

	if err := distribution.WritePullData(pd, filepath.Join(pm.libRoot, pluginID), true); err != nil {
		logrus.Debugf("error in distribution.WritePullData(): %v", err)
		return nil, err
	}

	p := pm.newPlugin(ref, pluginID)
	if err := pm.initPlugin(p); err != nil {
		return nil, err
	}

	pm.Lock()
	pm.plugins[pluginID] = p
	pm.nameToID[name] = pluginID
	pm.save()
	pm.Unlock()

	return computePrivileges(&p.P.Manifest), nil
}

// List displays the list of plugins and associated metadata.
func (pm *Manager) List() ([]types.Plugin, error) {
	out := make([]types.Plugin, 0, len(pm.plugins))
	for _, p := range pm.plugins {
		out = append(out, p.P)
	}
	return out, nil
}

// Push pushes a plugin to the store.
func (pm *Manager) Push(name string, metaHeader http.Header, authConfig *types.AuthConfig) error {
	p, err := pm.get(name)
	if err != nil {
		return err
	}
	dest := filepath.Join(pm.libRoot, p.P.ID)
	config, err := os.Open(filepath.Join(dest, "manifest.json"))
	if err != nil {
		return err
	}
	defer config.Close()

	rootfs, err := archive.Tar(filepath.Join(dest, "rootfs"), archive.Gzip)
	if err != nil {
		return err
	}
	_, err = distribution.Push(name, pm.registryService, metaHeader, authConfig, config, rootfs)
	// XXX: Ignore returning digest for now.
	// Since digest needs to be written to the ProgressWriter.
	return err
}

// Remove deletes plugin's root directory.
func (pm *Manager) Remove(name string) error {
	p, err := pm.get(name)
	if err != nil {
		return err
	}
	return pm.remove(p)
}

// Set sets plugin args
func (pm *Manager) Set(name string, args []string) error {
	p, err := pm.get(name)
	if err != nil {
		return err
	}
	return pm.set(p, args)
}
