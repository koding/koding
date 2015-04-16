package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"koding/artifact"
	"koding/kites/cmd/terraformer/pkg"
	"koding/kites/common"
	"koding/kites/terraformer"
	"log"
	"os"
	"os/signal"
	"path"
	"strconv"
	"time"

	"github.com/hashicorp/terraform/command"
	"github.com/hashicorp/terraform/plugin"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/metrics"
	"github.com/koding/multiconfig"
	"github.com/mitchellh/cli"
)

var (
	Name    = "terraformer"
	Version = "0.0.1"
)

// Ui is the cli.Ui used for communicating to the outside world.
var Ui cli.Ui

const (
	ErrorPrefix  = "e:"
	OutputPrefix = "o:"
)

func main() {
	b := new(bytes.Buffer)

	Ui = &cli.PrefixedUi{
		AskPrefix:    OutputPrefix,
		OutputPrefix: OutputPrefix,
		InfoPrefix:   OutputPrefix,
		ErrorPrefix:  ErrorPrefix,

		// we can override this later easily
		Ui: &cli.BasicUi{Writer: b},
	}

	config := pkg.BuiltinConfig
	if err := config.Discover(); err != nil {
		Ui.Error(fmt.Sprintf("Error discovering plugins: %s", err))
		os.Exit(1)
	}

	// Run checkpoint
	go pkg.RunCheckpoint(&config)

	// Make sure we clean up any managed plugins at the end of this
	defer plugin.CleanupClients()

	copts := &terraform.ContextOpts{
		Destroy:     false, // this should be true with kite.destroy command
		Parallelism: 0,

		Diff:  nil,
		Hooks: nil,

		// set at following lines
		Module: nil,
		// set at following lines
		State: nil,

		Providers:    config.ProviderFactories(),
		Provisioners: config.ProvisionerFactories(),
		// Targets      []string
		Variables: map[string]string{
			"aws_access_key":   "AKIAJTDKW5IFUUIWVNAA",
			"aws_region":       "sa-east-1",
			"aws_secret_key":   "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",
			"cidr_block":       "10.0.0.0/16",
			"environment_name": "kodingterraformtest",
		},
	}

	// c := &config.Config{}
	// mod := module.NewTree("kloud", c)
	// // mod.Load
	// // // Store the loaded state
	// // state, err := meta.State()
	// // if err != nil {
	// // 	panic(err)
	// // }

	// copts.State = &terraform.State{
	// 	Modules: []*terraform.ModuleState{
	// 		&terraform.ModuleState{
	// 			Path: []string{"root"},
	// 			Resources: map[string]*terraform.ResourceState{
	// 				"aws_instance.foo": &terraform.ResourceState{
	// 					Type: "aws_instance",
	// 					Primary: &terraform.InstanceState{
	// 						ID: "aws",
	// 					},
	// 				},
	// 			},
	// 		},
	// 	},
	// }
	// copts.Module = mod

	// // TODO - there is smth to be done in this copts - check it
	// // opts := m.contextOpts() does smth internally
	// ctx := terraform.NewContext(copts)
	// s, err := ctx.Apply()
	// fmt.Println("s, err-->", s, err)
	// return

	meta := command.Meta{
		Color:       false,
		ContextOpts: copts,
		Ui:          Ui,
	}

	// applycommand := command.ApplyCommand{
	applycommand := command.PlanCommand{
		Meta: meta,

		// If true, then this apply command will become the "destroy"
		// command. It is just like apply but only processes a destroy.
		// Destroy: false,

		// When this channel is closed, the apply will be cancelled.
		// ShutdownCh: makeShutdownCh(),
	}

	folder, err := createDirAndFile()
	if err != nil {
		log.Fatalf("err dir: %s", err)
	}

	// dont forget to

	// if err := tf.Close(); err != nil {
	// 	log.Fatalf("err: %s", err)
	// }
	// if err := os.Remove(result); err != nil {
	// 	log.Fatalf("err: %s", err)
	// }

	s := applycommand.Run([]string{
		"-no-color", // dont write with color
		folder,
	})

	fmt.Println("applycommand-->", s)
	fmt.Println("b.String()-->", b.String())
	os.Exit(s)

	conf := &terraformer.Config{}

	// Load the config, reads environment variables or from flags
	multiconfig.New().MustLoad(conf)

	k := newKite(conf)

	registerURL := k.RegisterURL(true)

	if err := k.RegisterForever(registerURL); err != nil {
		k.Log.Fatal(err.Error())
	}

	k.Run()
}

func createDirAndFile() (string, error) {
	// create dir
	dir, err := ioutil.TempDir("", "terraformer")
	if err != nil {
		log.Fatalf("err dir: %s", err)
	}

	path := path.Join(dir, strconv.Itoa(int(time.Now().Unix()))+".tf")
	tf, err := os.Create(path)
	if err != nil {
		log.Fatalf("err file: %s", err)
	}

	_, err = tf.WriteString(SampleTF)
	if err != nil {
		log.Fatalf("err write string: %s", err)
	}

	return dir, nil
}

// makeShutdownCh creates an interrupt listener and returns a channel.
// A message will be sent on the channel for every interrupt received.
func makeShutdownCh() <-chan struct{} {
	resultCh := make(chan struct{})

	signalCh := make(chan os.Signal, 4)
	signal.Notify(signalCh, os.Interrupt)
	go func() {
		for {
			<-signalCh
			resultCh <- struct{}{}
		}
	}()

	return resultCh
}

func newKite(conf *terraformer.Config) *kite.Kite {
	k := kite.New(Name, Version)
	k.Config = kiteconfig.MustGet()
	k.Config.Port = conf.Port

	if conf.Region != "" {
		k.Config.Region = conf.Region
	}

	if conf.Environment != "" {
		k.Config.Environment = conf.Environment
	}

	if conf.Debug {
		k.SetLogLevel(kite.DEBUG)
	}

	stats := common.MustInitMetrics(Name)

	t := terraformer.New()
	t.Metrics = stats
	t.Log = common.NewLogger(Name, conf.Debug)
	t.Debug = conf.Debug

	// track every kind of call
	k.PreHandleFunc(createTracker(stats))

	// Terraformer handling methods
	k.HandleFunc("apply", t.Apply)
	k.HandleFunc("destroy", t.Destroy)
	k.HandleFunc("plan", t.Plan)

	k.HandleHTTPFunc("/healthCheck", artifact.HealthCheckHandler(Name))
	k.HandleHTTPFunc("/version", artifact.VersionHandler())

	return k
}

func createTracker(metrics *metrics.DogStatsD) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		metrics.Count(
			"functionCallCount", // metric name
			1,                   // count
			[]string{"funcName:" + r.Method}, // tags for metric call
			1.0, // rate
		)

		return true, nil
	}
}
