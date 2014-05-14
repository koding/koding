package packer

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"

	"github.com/mitchellh/packer/builder/digitalocean"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/provisioner/file"
	"github.com/mitchellh/packer/provisioner/shell"
)

type Provider struct {
	BuildName    string
	TemplatePath string
	Vars         map[string]string
	EnableDebug  bool
}

func (p *Provider) Build() ([]packer.Artifact, error) {
	template, err := p.newTemplateFile()
	if err != nil {
		return nil, err
	}

	build, err := template.Build(p.BuildName, newComponentFinder())
	if err != nil {
		return nil, err
	}

	if !p.EnableDebug {
		build.SetDebug(false)
		log.SetOutput(ioutil.Discard)
	}

	_, err = build.Prepare()
	if err != nil {
		return nil, err
	}

	// Handle interrupts for this build
	sigCh := make(chan os.Signal, 1)
	signal.Notify(sigCh, os.Interrupt)
	defer signal.Stop(sigCh)
	go func(b packer.Build) {
		<-sigCh

		log.Printf("Stopping build: %s", b.Name())
		b.Cancel()
		log.Printf("Build cancelled: %s", b.Name())
	}(build)

	return build.Run(p.coloredUi(), p.cache())
}

func (p *Provider) coloredUi() packer.Ui {
	return &packer.ColoredUi{
		Color: packer.UiColorGreen,
		Ui:    p.basicUI(),
	}
}

func (p *Provider) cache() packer.Cache {
	return &packer.FileCache{
		CacheDir: os.TempDir(),
	}
}

func (p *Provider) basicUI() packer.Ui {
	return &packer.BasicUi{
		Reader:      os.Stdin,
		Writer:      os.Stdout,
		ErrorWriter: os.Stdout,
	}
}

func (p *Provider) newTemplateFile() (*packer.Template, error) {
	template, err := packer.ParseTemplateFile(p.TemplatePath, p.Vars)
	if err != nil {
		return nil, fmt.Errorf("Failed to parse template: %s", err)
	}

	if len(template.Builders) == 0 {
		return nil, errors.New("No builder is available")
	}

	if len(template.Builders) != 1 {
		return nil, errors.New("Only on builder is supported currently")
	}

	if _, ok := template.Builders[p.BuildName]; !ok {
		return nil, fmt.Errorf("Build '%s' does not exist", p.BuildName)
	}

	return template, nil
}

func newComponentFinder() *packer.ComponentFinder {
	return &packer.ComponentFinder{
		Builder:       builderFunc,
		Command:       commandFunc,
		Provisioner:   provisionerFunc,
		Hook:          hookFunc,
		PostProcessor: postProcessorFunc,
	}
}

func builderFunc(name string) (packer.Builder, error) {
	switch name {
	case "digitalocean":
		return &digitalocean.Builder{}, nil
	}

	return nil, errors.New("no suitable build found")
}

func provisionerFunc(name string) (packer.Provisioner, error) {
	switch name {
	case "file":
		return &file.Provisioner{}, nil
	case "shell":
		return &shell.Provisioner{}, nil
	}

	return nil, errors.New("no suitable provisioner found")
}

func hookFunc(name string) (packer.Hook, error) {
	return nil, errors.New("not supported")
}

func postProcessorFunc(name string) (packer.PostProcessor, error) {
	return nil, errors.New("not supported")
}

func commandFunc(name string) (packer.Command, error) {
	return nil, errors.New("not supported")
}
