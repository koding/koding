// Package main provides cli for gene package
package main

import (
	"log"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/generators/functions"
	"github.com/cihangir/gene/generators/mainfile"
	"github.com/cihangir/gene/generators/sql/statements"
	"github.com/koding/multiconfig"

	_ "github.com/cihangir/govalidator"
	_ "github.com/cihangir/stringext"
	_ "github.com/lann/squirrel"
	_ "golang.org/x/net/context"
)

// Config holds configuration data for gene
type Config struct {
	// Schema holds the given schema file
	Schema string `required:"true"`

	// Target holds the target folder
	Target string `required:"true" default:"./"`

	// Generators holds the generator names for processing
	Generators []string `default:"ddl,rows,kit,errors,dockerfiles,clients,functions,models,js"`

	Statements statements.Generator
	Mainfile   mainfile.Generator
	Functions  functions.Generator
	// Js         js.Generator
}

func main() {
	conf := &Config{}
	g, err := common.Discover("gene-*")
	if err != nil {
		log.Fatalf("err %s", err.Error())
	}
	defer g.Shutdown()

	loader := multiconfig.MultiLoader(
		&multiconfig.TagLoader{},  // assign default values
		&multiconfig.FlagLoader{}, // read flag params
	)

	if err := loader.Load(conf); err != nil {
		log.Fatalf("config read err: %s", err.Error())
	}

	if err := (&multiconfig.RequiredValidator{}).Validate(conf); err != nil {
		log.Fatalf("validation err: %s", err.Error())
	}

	c := common.NewContext()
	c.Config.Target = conf.Target
	c.Config.Generators = conf.Generators

	str, err := common.ReadJSON(conf.Schema)
	if err != nil {
		log.Fatalf("schema read err: %s", err.Error())
	}

	for name, client := range g.Clients {
		log.Print("generating for ", name)

		rpcClient, err := client.Client()
		if err != nil {
			log.Fatalf("couldnt start client: %s", err)
		}
		defer rpcClient.Close()

		raw, err := rpcClient.Dispense("generate")
		if err != nil {
			log.Fatalf("couldnt get the client: %s", err.Error())
		}

		gene := (raw).(common.Generator)
		req := &common.Req{
			SchemaStr: str,
			Context:   c,
		}

		res := &common.Res{}
		err = gene.Generate(req, res)
		if err != nil {
			log.Fatalf("err while generating content for %s, err: %# v", name, err)
		}

		if err := common.WriteOutput(res.Output); err != nil {
			log.Fatalf("output write err: %s", err.Error())
		}
	}

	//
	// generate crud statements
	//
	// c.Config.Target = conf.Target + "models" + "/"
	// output, err = conf.Statements.Generate(c, s)
	// if err != nil {
	// 	log.Fatalf("err while generating crud statements", err.Error())
	// }

	// if err := common.WriteOutput(output); err != nil {
	// 	log.Fatal("output write err: %s", err.Error())
	// }

	//
	// generate main file
	//
	// c.Config.Target = conf.Target + "cmd" + "/"
	// output, err = conf.Mainfile.Generate(c, s)
	// if err != nil {
	// 	log.Fatalf("err while generating main file", err.Error())
	// }

	// if err := common.WriteOutput(output); err != nil {
	// 	log.Fatal("output write err: %s", err.Error())
	// }

	//
	// generate exported functions
	//
	// c.Config.Target = conf.Target + "workers" + "/"
	// output, err = conf.Functions.Generate(c, s)
	// if err != nil {
	// 	log.Fatalf("err while generating clients", err.Error())
	// }

	// if err := common.WriteOutput(output); err != nil {
	// 	log.Fatal("output write err: %s", err.Error())
	// }

	//
	// generate js client functions
	//
	// c.Config.Target = conf.Target + "js" + "/"
	// output, err = conf.Js.Generate(c, s)
	// if err != nil {
	// 	log.Fatalf("err while generating js clients", err.Error())
	// }

	// if err := common.WriteOutput(output); err != nil {
	// 	log.Fatal("output write err: %s", err.Error())
	// }

	log.Println("module created with success")
}
