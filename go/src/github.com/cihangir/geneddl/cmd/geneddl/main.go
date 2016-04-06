// Package main provides cli for geneddl package
package main

import (
	"log"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/geneddl"
	"github.com/koding/multiconfig"
)

type Config struct {
	Schema string `required:"true"`
	Target string `default:"ddl"`
	DDL    geneddl.Generator
}

func main() {
	conf := &Config{}

	loader := multiconfig.MultiLoader(
		&multiconfig.TagLoader{},  // assign default values
		&multiconfig.FlagLoader{}, // read flag params
		&multiconfig.EnvironmentLoader{},
	)

	if err := loader.Load(conf); err != nil {
		log.Fatalf("config read err: %s", err.Error())
	}

	if err := (&multiconfig.RequiredValidator{}).Validate(conf); err != nil {
		log.Fatalf("validation err: %s", err.Error())
	}

	c := common.NewContext()
	c.Config.Schema = conf.Schema
	c.Config.Target = conf.Target

	s, err := common.Read(c.Config.Schema)
	if err != nil {
		log.Fatalf("schema read err: %s", err.Error())
	}

	s = s.Resolve(s)

	req := &common.Req{
		Schema:  s,
		Context: c,
	}
	res := &common.Res{}
	err = conf.DDL.Generate(req, res)
	if err != nil {
		log.Fatal("geneddl err: %s", err.Error())
	}

	if err := common.WriteOutput(res.Output); err != nil {
		log.Fatal("output write err: %s", err.Error())
	}

	log.Println("module created with success")
}
