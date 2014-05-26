package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"koding/kites/kloud/digitalocean"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"net/url"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/fatih/color"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"
)

const (
	testUser = "testkloud"
)

var (
	kloud           *kodingkite.KodingKite
	remote          *kite.Client
	flagTestDebug   = flag.Bool("debug", false, "Enable debug")
	flagTestBuilds  = flag.Int("builds", 1, "Number of builds")
	flagTestDestroy = flag.Bool("no-destroy", false, "Do not destroy test machines")

	DIGITALOCEAN_CLIENT_ID       = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY         = "4c88127b50c0c731aeb5129bdea06deb"
	DIGITALOCEAN_TEST_DROPLET_ID = 1657055
)

var TestProviderData = map[string]map[string]interface{}{
	"digitalocean": map[string]interface{}{
		"provider": "digitalocean",
		"credential": map[string]interface{}{
			"client_id": DIGITALOCEAN_CLIENT_ID,
			"api_key":   DIGITALOCEAN_API_KEY,
		},
		"machineId": DIGITALOCEAN_TEST_DROPLET_ID,
		"builder": map[string]interface{}{
			"type":          "digitalocean",
			"client_id":     DIGITALOCEAN_CLIENT_ID,
			"api_key":       DIGITALOCEAN_API_KEY,
			"image":         "ubuntu-13-10-x64",
			"region":        "sfo1",
			"size":          "512mb",
			"snapshot_name": "koding-{{timestamp}}",
		},
	},
	"amazon-instance": nil,
	"googlecompute":   nil,
}

func init() {
	flag.Parse()

	conf := kiteconfig.New()
	conf.Username = "testuser"
	conf.KontrolURL = &url.URL{Scheme: "ws", Host: "localhost:4444"}
	conf.KontrolKey = testkeys.Public
	conf.KontrolUser = "testuser"
	conf.KiteKey = testutil.NewKiteKey().Raw
	conf.Port = 4444

	kon := kontrol.New(conf.Copy(), "0.1.0", testkeys.Public, testkeys.Private)
	kon.DataDir, _ = ioutil.TempDir("", "")
	defer os.RemoveAll(kon.DataDir)
	go kon.Run()
	<-kon.Kite.ServerReadyNotify()

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

	k := &Kloud{
		Name:              "kloud-test",
		Version:           "0.0.1",
		Region:            "vagrant",
		Port:              3636,
		Config:            kloudConf,
		KontrolURL:        "wss://kontrol.koding.com",
		KontrolPrivateKey: privateKey,
		KontrolPublicKey:  publicKey,
	}

	kloud = k.NewKloud()
	kloud.Config.DisableAuthentication = true
	kloud.Config.KontrolURL = &url.URL{Scheme: "ws", Host: "localhost:4444"}

	go kloud.Run()
	<-kloud.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config = conf

	kites, err := client.GetKites(protocol.KontrolQuery{
		Username:    "testuser",
		Environment: "vagrant",
		Name:        "kloud-test",
	})
	if err != nil {
		log.Fatalln(err)
	}

	remote = kites[0]
	if err := remote.Dial(); err != nil {
		log.Fatal(err)
	}

	// To disable packer output, comment it out for debugging
	if !*flagTestDebug {
		log.SetOutput(ioutil.Discard)
	}
}

func TestProviders(t *testing.T) {
	t.Skip("To enable this test remove this line")
	for provider, data := range TestProviderData {
		if data == nil {
			color.Yellow("==> %s skipping test. test data is not available.", provider)
			continue
		}

		testlog := func(msg string, args ...interface{}) {
			// mimick it like packer's own log
			color.Cyan("==> %s: %s", provider, fmt.Sprintf(msg, args...))
		}

		snapshotName := "testkoding-" + strconv.FormatInt(time.Now().UTC().Unix(), 10)

		testlog("Starting tests")
		bArgs := &buildArgs{
			Provider:     data["provider"].(string),
			Credential:   data["credential"].(map[string]interface{}),
			Builder:      data["builder"].(map[string]interface{}),
			SnapshotName: snapshotName,
		}

		start := time.Now()
		resp, err := remote.Tell("build", bArgs)
		if err != nil {
			t.Fatal(err)
		}
		testlog("Building image and creating the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		var result digitalocean.Droplet
		err = resp.Unmarshal(&result)
		if err != nil {
			t.Fatal(err)
		}

		// droplet's names are based on username for now
		if result.Name != testUser {
			t.Error("droplet name is: %s, expecting: %s", result.Name, testUser)
		}

		dropletId := result.Id

		cArgs := &controllerArgs{
			Provider:   data["provider"].(string),
			Credential: data["credential"].(map[string]interface{}),
			MachineID:  dropletId,
		}

		start = time.Now()
		if _, err := remote.Tell("stop", cArgs); err != nil {
			t.Errorf("stop: %s", err)
		}
		testlog("Stopping the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		start = time.Now()
		if _, err := remote.Tell("start", cArgs); err != nil {
			t.Errorf("start: %s", err)
		}
		testlog("Starting the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		start = time.Now()
		if _, err := remote.Tell("restart", cArgs); err != nil {
			t.Errorf("restart: %s", err)
		}
		testlog("Restarting the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		start = time.Now()
		if _, err := remote.Tell("info", cArgs); err != nil {
			t.Errorf("info: %s", err)
		}
		testlog("Getting info about the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		start = time.Now()
		if _, err := remote.Tell("destroy", cArgs); err != nil {
			t.Errorf("destroy: %s", err)
		}
		testlog("Destroying the machine. Elapsed time %f seconds", time.Since(start).Seconds())
	}
}

func TestBuild(t *testing.T) {
	// t.Skip("To enable this test remove this line")

	numberOfBuilds := *flagTestBuilds

	for provider, data := range TestProviderData {
		if data == nil {
			color.Yellow("==> %s skipping test. test data is not available.", provider)
			continue
		}

		buildFunc := func(i int) {
			machineName := "testkloud-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10) + "-" + strconv.Itoa(i)

			bArgs := &buildArgs{
				Provider:    data["provider"].(string),
				Credential:  data["credential"].(map[string]interface{}),
				Builder:     data["builder"].(map[string]interface{}),
				MachineName: machineName,
			}

			resp, err := remote.Tell("build", bArgs)
			if err != nil {
				t.Fatal(err)
			}

			var result digitalocean.Droplet
			err = resp.Unmarshal(&result)
			if err != nil {
				t.Fatal(err)
			}

			// droplet's names are based on username for now
			if result.Name != machineName {
				t.Errorf("droplet name is: %s, expecting: %s", result.Name, machineName)
			}

			fmt.Println("============")
			fmt.Printf("result %+v\n", result)
			fmt.Println("============")

			if !*flagTestDestroy {
				fmt.Println("destroying ", machineName)
				dropletId := result.Id
				cArgs := &controllerArgs{
					Provider:   data["provider"].(string),
					Credential: data["credential"].(map[string]interface{}),
					MachineID:  dropletId,
				}

				if _, err := remote.Tell("destroy", cArgs); err != nil {
					t.Errorf("destroy: %s", err)
				}
			}
		}

		var wg sync.WaitGroup
		for i := 0; i < numberOfBuilds; i++ {
			wg.Add(1)

			go func(i int) {
				defer wg.Done()
				buildFunc(i)
			}(i)
		}

		wg.Wait()
	}

}

//
// func TestStart(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("start", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestStop(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("stop", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestRestart(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	_, err := remote.Tell("restart", args)
//
// 	fmt.Printf("\n==== err: %+v\n\n", err)
// }
//
// func TestInfo(t *testing.T) {
// 	clientID, apiKey := digitalOceanKeys()
// 	args := &controllerArgs{
// 		Provider: "digitalocean",
// 		Credential: map[string]interface{}{
// 			"client_id": clientID,
// 			"api_key":   apiKey,
// 		},
// 		MachineID: TestDropletId,
// 	}
//
// 	for provider, data := range TestProviderData {
//
// 	}
//
// 	resp, err := remote.Tell("info", args)
// 	if err != nil {
// 		t.Fatal(err)
// 	}
//
// 	var result Droplet
// 	err = resp.Unmarshal(&result)
// 	if err != nil {
// 		t.Fatal(err)
// 	}
//
// 	fmt.Printf("result %+v\n", result)
// }
