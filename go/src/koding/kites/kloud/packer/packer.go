package packer

import (
	"errors"
	"fmt"
	"os"

	"github.com/mitchellh/packer/builder/digitalocean"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/provisioner/file"
	"github.com/mitchellh/packer/provisioner/shell"
)

func NewBuild(path, name string, vars map[string]string) ([]packer.Artifact, error) {
	template, err := newTemplate(path, name, vars)
	if err != nil {
		return nil, err
	}

	build, err := template.Build(name, NewComponentFinder())
	if err != nil {
		return nil, err
	}

	defer func() {
		if err != nil {
			build.Cancel()
		}
	}()

	_, err = build.Prepare()
	if err != nil {
		return nil, err
	}

	return build.Run(
		&packer.BasicUi{
			Reader:      os.Stdin,
			Writer:      os.Stdout,
			ErrorWriter: os.Stderr,
		},
		&packer.FileCache{
			CacheDir: os.TempDir(),
		},
	)
}

func newTemplate(path, build string, vars map[string]string) (*packer.Template, error) {
	template, err := packer.ParseTemplateFile(path, vars)
	if err != nil {
		return nil, fmt.Errorf("Failed to parse template: %s", err)
	}

	if len(template.Builders) == 0 {
		return nil, errors.New("No builder is available")
	}

	if len(template.Builders) != 1 {
		return nil, errors.New("Only on builder is supported currently")
	}

	if _, ok := template.Builders[build]; !ok {
		return nil, fmt.Errorf("Build '%s' does not exist", build)
	}

	return template, nil
}

func NewComponentFinder() *packer.ComponentFinder {
	return &packer.ComponentFinder{
		Builder:       BuilderFunc,
		Command:       CommandFunc,
		Provisioner:   ProvisionerFunc,
		Hook:          HookFunc,
		PostProcessor: PostProcessorFunc,
	}
}

func BuilderFunc(name string) (packer.Builder, error) {
	switch name {
	case "digitalocean":
		return &digitalocean.Builder{}, nil
	}

	return nil, errors.New("no suitable build found")
}

func ProvisionerFunc(name string) (packer.Provisioner, error) {
	switch name {
	case "file":
		return &file.Provisioner{}, nil
	case "shell":
		return &shell.Provisioner{}, nil
	}

	return nil, errors.New("no suitable provisioner found")
}

func HookFunc(name string) (packer.Hook, error) {
	return nil, errors.New("not supported")
}

func PostProcessorFunc(name string) (packer.PostProcessor, error) {
	return nil, errors.New("not supported")
}

func CommandFunc(name string) (packer.Command, error) {
	return nil, errors.New("not supported")
}
