package common

import (
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/hashicorp/go-plugin"
	"github.com/mitchellh/osext"
)

// PluginStore holds plugin names and their clients
type PluginStore struct {
	Plugins map[string]string
	Clients map[string]*plugin.Client
}

// Discover searches for plugins located nearby with this binary and in PATH,
// matching given prefix name
func Discover(prefix string) (*PluginStore, error) {
	log.Printf("[DEBUG] discovering for : %s", prefix)

	g := &PluginStore{
		Plugins: make(map[string]string),
		Clients: make(map[string]*plugin.Client),
	}

	if err := g.discover(".", prefix); err != nil {
		return nil, err
	}

	exePath, err := osext.Executable()
	if err != nil {
		log.Printf("[ERR] Error loading exe directory: %s", err)
	} else {
		if err := g.discover(filepath.Dir(exePath), prefix); err != nil {
			return nil, err
		}
	}

	for name, path := range g.Plugins {
		g.Clients[name] = g.createPluginClient(path)
	}

	return g, nil
}

func (g *PluginStore) Shutdown() error {
	for _, pluginClient := range g.Clients {
		pluginClient.Kill()
	}

	return nil
}

func (g *PluginStore) discover(path, prefix string) error {
	var err error

	if !filepath.IsAbs(path) {
		path, err = filepath.Abs(path)
		if err != nil {
			return err
		}
	}

	return g.discoverSingle(prefix, filepath.Join(path, prefix), &g.Plugins)
}

func (g *PluginStore) discoverSingle(prefix, glob string, m *map[string]string) error {
	matches, err := filepath.Glob(glob)
	if err != nil {
		return err
	}

	if *m == nil {
		*m = make(map[string]string)
	}

	for _, match := range matches {
		file := filepath.Base(match)
		// If the filename has a ".", trim up to there
		if idx := strings.Index(file, "."); idx >= 0 {
			file = file[:idx]
		}

		parts := strings.Split(file, "-")

		if len(parts)-1 != strings.Count(prefix, "-") {
			continue
		}

		pluginName := parts[len(parts)-1]
		log.Printf("[DEBUG] Discovered plugin: %s = %s", pluginName, match)
		(*m)[pluginName] = match
	}

	return nil
}

func (g *PluginStore) createPluginClient(path string) *plugin.Client {
	config := &plugin.ClientConfig{
		Cmd:             pluginCmd(path),
		HandshakeConfig: HandshakeConfig,
		Plugins: map[string]plugin.Plugin{
			// client wont use underlying plugin for serving, so a default empty plugin will work
			"generate": &GeneratorPlugin{},
		},
	}

	return plugin.NewClient(config)
}

func pluginCmd(path string) *exec.Cmd {
	cmdPath := ""

	// If the path doesn't contain a separator, look in the same
	// directory as the gene executable first.
	if !strings.ContainsRune(path, os.PathSeparator) {
		exePath, err := osext.Executable()
		if err == nil {
			temp := filepath.Join(
				filepath.Dir(exePath),
				filepath.Base(path))

			if _, err := os.Stat(temp); err == nil {
				cmdPath = temp
			}
		}

		// If we still haven't found the executable, look for it
		// in the PATH.
		if v, err := exec.LookPath(path); err == nil {
			cmdPath = v
		}
	}

	// If we still don't have a path, then just set it to the original
	// given path.
	if cmdPath == "" {
		cmdPath = path
	}

	// Build the command to execute the plugin
	return exec.Command(cmdPath)
}
