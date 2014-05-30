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
	"net/url"
	"os"
	"strconv"
	"sync"
	"testing"
	"time"

	"github.com/fatih/color"
	"github.com/koding/kite"
	kiteconfig "github.com/koding/kite/config"
	"github.com/koding/kite/kitekey"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"
	"github.com/mitchellh/mapstructure"
)

type TestStorage struct{}

func (t *TestStorage) Get(id string) (*kloud.MachineData, error) {
	provider := TestProviderData[id]

	return &kloud.MachineData{
		Provider:   provider["provider"].(string),
		Credential: provider["credential"].(map[string]interface{}),
		Builders:   provider["builder"].(map[string]interface{}),
	}, nil
}

func (t *TestStorage) Update(id string, data map[string]interface{}) error {
	response := &kloud.BuildResponse{}
	if err := mapstructure.Decode(data, response); err != nil {
		return err
	}

	provider := TestProviderData[id]
	b := provider["builder"].(map[string]interface{})
	b["machineId"] = strconv.Itoa(response.MachineId)
	b["machineName"] = response.MachineName

	provider["builder"] = b

	TestProviderData[id] = provider
	return nil
}

var (
	conf      *kiteconfig.Config
	kloudKite *kodingkite.KodingKite
	kloudRaw  *kloud.Kloud
	remote    *kite.Client
	testuser  string

	flagTestBuilds   = flag.Int("builds", 1, "Number of builds")
	flagTestDestroy  = flag.Bool("no-destroy", false, "Do not destroy test machines")
	flagTestUsername = flag.String("user", "", "Create machines on behalf of this user")

	DIGITALOCEAN_CLIENT_ID = "2d314ba76e8965c451f62d7e6a4bc56f"
	DIGITALOCEAN_API_KEY   = "4c88127b50c0c731aeb5129bdea06deb"

	TestProviderData = map[string]map[string]interface{}{
		"digitalocean": map[string]interface{}{
			"provider": "digitalocean",
			"credential": map[string]interface{}{
				"clientId": DIGITALOCEAN_CLIENT_ID,
				"apiKey":   DIGITALOCEAN_API_KEY,
			},
			"builder": map[string]interface{}{
				"type":          "digitalocean",
				"clientId":      DIGITALOCEAN_CLIENT_ID,
				"apiKey":        DIGITALOCEAN_API_KEY,
				"image":         "ubuntu-13-10-x64",
				"region":        "sfo1",
				"size":          "512mb",
				"snapshot_name": "koding-{{timestamp}}",
			},
		},
		"amazon-instance": nil,
		"googlecompute":   nil,
	}
)

func init() {
	flag.Parse()

	testuser = "testuser" // same as in kite.key
	if *flagTestUsername != "" {
		os.Setenv("TESTKEY_USERNAME", *flagTestUsername)
		testuser = *flagTestUsername
	}

	// now create a new test key with the given test username
	kitekey.Write(testutil.NewKiteKey().Raw)

	conf = kiteconfig.New()
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

	kloudKite = setupKloud()
	kloudKite.Config.DisableAuthentication = true
	kloudKite.Config.KontrolURL = &url.URL{Scheme: "ws", Host: "localhost:4444"}

	go kloudKite.Run()
	<-kloudKite.ServerReadyNotify()

	client := kite.New("client", "0.0.1")
	client.Config = conf.Copy()

	kites, err := client.GetKites(protocol.KontrolQuery{
		Username:    testuser,
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

	// To disable packer output, comment it out for debugging
	if !*flagDebug {
		log.SetOutput(ioutil.Discard)
	}

	rand.Seed(time.Now().UTC().UnixNano())
}

func build(i int, client *kite.Client, data map[string]interface{}) error {
	machineName := "testkloud-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10) + "-" + strconv.Itoa(i)

	bArgs := &kloud.BuildArgs{
		MachineId:   data["provider"].(string),
		MachineName: machineName,
	}

	resp, err := client.Tell("build", bArgs)
	if err != nil {
		return err
	}

	var result kloud.BuildResponse
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	// droplet's names are based on username for now
	if result.MachineName != machineName {
		return fmt.Errorf("droplet name is: %s, expecting: %s", result.MachineName, machineName)
	}

	fmt.Println("============")
	fmt.Printf("result %+v\n", result)
	fmt.Println("============")

	if !*flagTestDestroy {
		fmt.Println("destroying ", machineName)

		cArgs := &kloud.ControllerArgs{
			MachineId: data["provider"].(string),
		}

		if _, err := client.Tell("destroy", cArgs); err != nil {
			return fmt.Errorf("destroy: %s", err)
		}
	}

	return nil
}

func TestMultiple(t *testing.T) {
	t.Skip("To enable this test remove this line")

	// number of clients that will query example kites
	clientNumber := 10

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
			clientConf := conf.Copy()
			// username := "testuser" + strconv.Itoa(i)
			// clientConf.Username = username
			c.Config = clientConf
			clientsMu.Unlock()

			c.SetupKontrolClient()

			kites, err := c.GetKites(protocol.KontrolQuery{
				Username:    testuser,
				Environment: "vagrant",
				Name:        "kloud",
			})
			if err != nil {
				t.Error(err)
				return
			}

			r := kites[0]

			if err := r.Dial(); err != nil {
				t.Error(err)
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

	// every one second
	for i := 0; i < clientNumber; i++ {
		wg.Add(1)

		go func(i int) {
			defer wg.Done()

			time.Sleep(time.Millisecond * time.Duration(rand.Intn(500)))

			for provider, data := range TestProviderData {
				if data == nil {
					color.Yellow("==> %s skipping test. test data is not available.", provider)
					continue
				}

				start := time.Now()

				clientsMu.Lock()
				c := clients[i]
				clientsMu.Unlock()

				err := build(i, c, data)
				elapsedTime := time.Since(start)

				if err != nil {
					fmt.Printf("[%d] aborted, elapsed %f sec err: %s\n",
						i, elapsedTime.Seconds(), err)
				} else {
					fmt.Printf("[%d] finished, elapsed %f sec\n", i, elapsedTime.Seconds())
				}
			}
		}(i)
	}

	wg.Wait()

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
		bArgs := &kloud.BuildArgs{
			MachineId:    data["provider"].(string),
			SnapshotName: snapshotName,
		}

		start := time.Now()
		resp, err := remote.Tell("build", bArgs)
		if err != nil {
			t.Fatal(err)
		}
		testlog("Building image and creating the machine. Elapsed time %f seconds", time.Since(start).Seconds())

		var result kloud.BuildResponse
		err = resp.Unmarshal(&result)
		if err != nil {
			t.Fatal(err)
		}

		cArgs := &kloud.ControllerArgs{
			MachineId: data["provider"].(string),
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

func TestBuilds(t *testing.T) {
	numberOfBuilds := *flagTestBuilds

	for provider, data := range TestProviderData {
		if data == nil {
			color.Yellow("==> %s skipping test. test data is not available.", provider)
			continue
		}

		var wg sync.WaitGroup
		for i := 0; i < numberOfBuilds; i++ {
			wg.Add(1)

			go func(i int) {
				defer wg.Done()
				time.Sleep(time.Millisecond * time.Duration(rand.Intn(2500))) // wait 0-2500 milliseconds
				if err := build(i, remote, data); err != nil {
					t.Error(err)
				}
			}(i)
		}

		wg.Wait()
	}

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
	}

	kt := kloudRaw.NewKloud()

	return kt
}
