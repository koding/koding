package packer

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/signal"

	"github.com/mitchellh/packer/builder/amazon/ebs"
	"github.com/mitchellh/packer/builder/digitalocean"
	"github.com/mitchellh/packer/packer"
	"github.com/mitchellh/packer/provisioner/file"
	"github.com/mitchellh/packer/provisioner/shell"
)

type Provider struct {
	BuildName    string
	TemplatePath string
	Builder      []byte
	Vars         map[string]string
	EnableDebug  bool
}

func (p *Provider) Build() error {
	var template *packer.Template
	var err error

	if p.Builder != nil {
		template, err = p.NewTemplate()
		if err != nil {
			return err
		}
	} else if p.TemplatePath != "" {
		template, err = p.NewTemplateFile()
		if err != nil {
			return err
		}
	} else {
		return errors.New("Can't find Template source, neither p.Builder or p.TemplatePath is defined")
	}

	if len(template.Builders) == 0 {
		return errors.New("No builder is available")
	}

	if len(template.Builders) != 1 {
		return errors.New("Only on builder is supported currently")
	}

	if _, ok := template.Builders[p.BuildName]; !ok {
		return fmt.Errorf("Build '%s' does not exist", p.BuildName)
	}

	build, err := template.Build(p.BuildName, newComponentFinder())
	if err != nil {
		return err
	}

	if !p.EnableDebug {
		build.SetDebug(false)
		log.SetOutput(ioutil.Discard)
	}

	_, err = build.Prepare()
	if err != nil {
		return err
	}

	// Handle interrupts for this build
	sig := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt)
	defer signal.Stop(sig)
	go func(b packer.Build) {
		<-sig

		log.Printf("Stopping build: %s", b.Name())
		b.Cancel()
		log.Printf("Build cancelled: %s", b.Name())
	}(build)

	artifacts, err := build.Run(p.coloredUi(), p.cache())
	if err != nil {
		return err
	}

	for _, a := range artifacts {
		fmt.Println(a.Files(), a.BuilderId(), a.Id(), a.String())
	}

	return nil
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

func (p *Provider) NewTemplate() (*packer.Template, error) {
	template, err := packer.ParseTemplate(p.Builder, p.Vars)
	if err != nil {
		return nil, fmt.Errorf("Failed to parse template: %s", err)
	}

	return template, nil
}

func (p *Provider) NewTemplateFile() (*packer.Template, error) {
	template, err := packer.ParseTemplateFile(p.TemplatePath, p.Vars)
	if err != nil {
		return nil, fmt.Errorf("Failed to parse template: %s", err)
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
	case "amazon-ebs":
		return &ebs.Builder{}, nil
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
