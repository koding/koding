package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/kloud"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"math/rand"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"koding/kites/kloud/kloud/machinestate"

	"github.com/fatih/color"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
)

var (
	flagTestBuilds     = flag.Int("builds", 1, "Number of builds")
	flagTestControl    = flag.Bool("control", false, "Enable control tests too (start/stop/..)")
	flagTestImage      = flag.Bool("image", false, "Create temporary image instead of using default one.")
	flagTestNoDestroy  = flag.Bool("no-destroy", false, "Do not destroy droplet")
	flagTestQuery      = flag.String("query", "", "Query as string for controller tests")
	flagTestInstanceId = flag.String("instance", "", "Instance id (such as droplet Id)")
	flagTestUsername   = flag.String("user", "", "Create machines on behalf of this user")

	conf      *kiteconfig.Config
	kloudKite *kodingkite.KodingKite
	kloudRaw  *kloud.Kloud
	remote    *kite.Client
	testuser  string
	storage   kloud.Storage

	DIGITALOCEAN_CLIENT_ID = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY   = "4c88127b50c0c731aeb5129bdea06deb"
)

func init() {
	flag.Parse()

	testuser = "testuser" // same as in kite.key
	if *flagTestUsername != "" {
		os.Setenv("TESTKEY_USERNAME", *flagTestUsername)
		testuser = *flagTestUsername
	}

	kloudKite = setupKloud()
	go kloudKite.Run()
	<-kloudKite.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config = kloudKite.Config.Copy()

	kites, err := client.GetKites(protocol.KontrolQuery{
		Username:    "koding",
		Environment: "vagrant",
		Name:        "kloud",
	})
	if err != nil {
		log.Fatalln(err)
	}

	remote = kites[0]
	if err := remote.Dial(); err != nil {
		log.Fatal(err)
	}

	// This disables packer output, comment it out for debugging packer
	log.SetOutput(ioutil.Discard)

	rand.Seed(time.Now().UTC().UnixNano())
}

// listenEvent calls the event method of kloud with the given arguments until
// the desiredState is received. It times out if the desired state is not
// reached in 10 miunuts.
func listenEvent(args kloud.EventArgs, desiredState machinestate.State) error {
	tryUntil := time.Now().Add(time.Minute * 10)
	for {
		resp, err := remote.Tell("event", args)
		if err != nil {
			return err
		}

		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return err
		}

		e := events[0]
		if e.Error != nil {
			return e.Error
		}

		event := e.Event

		if *flagDebug {
			fmt.Printf("event %+v\n", event)
		}

		if event.Status == desiredState {
			return nil
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for state %s", desiredState)
		}

		time.Sleep(2 * time.Second)
		continue // still pending
	}

	return nil
}

// build builds a single machine with the given client and data. Use this
// function to invoke concurrent and multiple builds.
func build(i int, client *kite.Client, data *kloud.MachineData) error {
	uniqueId := strconv.FormatInt(time.Now().UTC().UnixNano(), 10)

	imageName := "" // an empty argument causes to use the standard library.
	if *flagTestImage {
		imageName = testuser + "-" + uniqueId + "-" + strconv.Itoa(i)
	}

	instanceName := "testkloud-" + uniqueId + "-" + strconv.Itoa(i)

	testlog := func(msg string, args ...interface{}) {
		// mimick it like packer's own log
		color.Green("==> %s: %s", data.Provider, fmt.Sprintf(msg, args...))
	}

	bArgs := &kloud.Controller{
		MachineId:    data.Provider + "_id" + strconv.Itoa(i),
		InstanceName: instanceName,
		ImageName:    imageName,
	}

	start := time.Now()
	resp, err := client.Tell("build", bArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: bArgs.MachineId,
			Type:    "build",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running); err != nil {
		return err
	}
	testlog("Building the machine. Elapsed time %f seconds", time.Since(start).Seconds())

	if *flagTestControl {
		cArgs := &kloud.Controller{
			MachineId: data.Provider + "_id" + strconv.Itoa(i),
		}

		type pair struct {
			method       string
			desiredState machinestate.State
		}

		methodPairs := []pair{
			{method: "stop", desiredState: machinestate.Stopped},
			{method: "start", desiredState: machinestate.Running},
			{method: "restart", desiredState: machinestate.Running},
		}

		if !*flagTestNoDestroy {
			methodPairs = append(methodPairs, pair{
				method:       "destroy",
				desiredState: machinestate.Terminated,
			})
		}

		// do not change the order
		for _, pair := range methodPairs {
			if _, err := client.Tell(pair.method, cArgs); err != nil {
				return fmt.Errorf("%s: %s", pair.method, err)
			}

			eArgs := kloud.EventArgs([]kloud.EventArg{
				kloud.EventArg{
					EventId: bArgs.MachineId,
					Type:    pair.method,
				},
			})

			start := time.Now()
			if err := listenEvent(eArgs, pair.desiredState); err != nil {
				return err
			}
			testlog("%s finished. Elapsed time %f seconds\n", pair.method, time.Since(start).Seconds())
		}
	}

	return nil
}

func TestBuild(t *testing.T) {
	// t.SkipNow()
	numberOfBuilds := *flagTestBuilds

	if numberOfBuilds > 4 {
		t.Fatal("number of builds should be equal or less than 3")
	}

	var wg sync.WaitGroup
	for i := 0; i < numberOfBuilds; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()
			machineId := "digitalocean_id" + strconv.Itoa(i)
			data, ok := TestProviderData[machineId]
			if !ok {
				t.Errorf("machineId '%s' is not available", machineId)
				return
			}

			if err := build(i, remote, data); err != nil {
				t.Error(err)
			}
		}(i)
	}

	wg.Wait()
}

func TestRestart(t *testing.T) {
	t.SkipNow()
	if *flagTestQuery == "" {
		t.Fatal("Query is not defined for restart")
	}

	data := TestProviderData["digitalocean"]
	cArgs := &kloud.Controller{
		MachineId: data.Provider,
	}

	kloudRaw.Storage = TestStorageFunc(func(id string, opt *kloud.GetOption) (*kloud.MachineData, error) {
		machineData := TestProviderData[id]
		machineData.Machine.Status.State = machinestate.Running.String() // assume it's running
		machineData.Machine.QueryString = *flagTestQuery
		machineData.Machine.Meta["instanceId"] = *flagTestInstanceId
		return machineData, nil
	})

	if _, err := remote.Tell("restart", cArgs); err != nil {
		t.Errorf("destroy: %s", err)
	}

}

func TestMultiple(t *testing.T) {
	t.Skip("To enable this test remove this line")

	// number of clients that will query example kites
	clientNumber := 3

	fmt.Printf("Creating %d clients\n", clientNumber)

	var cg sync.WaitGroup

	clients := make([]*kite.Client, clientNumber)
	var clientsMu sync.Mutex

	for i := 0; i < clientNumber; i++ {
		cg.Add(1)

		go func(i int) {
			defer cg.Done()

			c := kite.New("client"+strconv.Itoa(i), "0.0.1")

			clientsMu.Lock()
			clientConf := kloudKite.Config.Copy()
			username := "testuser" + strconv.Itoa(i)
			clientConf.Username = username

			c.Config = clientConf
			clientsMu.Unlock()

			c.SetupKontrolClient()

			kites, err := c.GetKites(protocol.KontrolQuery{
				Username:    "koding",
				Environment: "vagrant",
				Name:        "kloud",
			})
			if err != nil {

				t.Fatal(err)
			}

			r := kites[0]

			if err := r.Dial(); err != nil {
				t.Fatal(err)
			}

			clientsMu.Lock()
			clients[i] = r
			clientsMu.Unlock()
		}(i)

	}

	cg.Wait()

	fmt.Printf("Calling with %d conccurent clients randomly. Starting after 3 seconds ...\n", clientNumber)
	time.Sleep(time.Second * 1)

	var wg sync.WaitGroup

	for i := 0; i < clientNumber; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()

			clientsMu.Lock()
			c := clients[i]
			clientsMu.Unlock()

			machineId := "digitalocean_id" + strconv.Itoa(i)
			data, ok := TestProviderData[machineId]
			if !ok {
				t.Errorf("machineId '%s' is not available", machineId)
				return
			}

			if err := build(i, c, data); err != nil {
				t.Error(err)
			}
		}(i)
	}

	wg.Wait()

}

func setupKloud() *kodingkite.KodingKite {
	kloudConf := config.MustConfig("vagrant")

	pubKeyPath := *flagPublicKey
	if *flagPublicKey == "" {
		pubKeyPath = kloudConf.NewKontrol.PublicKeyFile
	}
	pubKey, err := ioutil.ReadFile(pubKeyPath)
	if err != nil {
		log.Fatalln(err)
	}
	publicKey := string(pubKey)

	privKeyPath := *flagPrivateKey
	if *flagPublicKey == "" {
		privKeyPath = kloudConf.NewKontrol.PrivateKeyFile
	}
	privKey, err := ioutil.ReadFile(privKeyPath)
	if err != nil {
		log.Fatalln(err)
	}
	privateKey := string(privKey)

	kloudRaw = &kloud.Kloud{
		Region:            "vagrant",
		Port:              3636,
		Config:            kloudConf,
		Storage:           &TestStorage{},
		KontrolURL:        "wss://kontrol.koding.com",
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
		Debug:             *flagDebug,
	}

	kt := kloudRaw.NewKloud()

	return kt
}
