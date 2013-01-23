package utils

import (
	cryptorand "crypto/rand"
	"encoding/base64"
	"encoding/binary"
	"flag"
	"fmt"
	"koding/tools/config"
	"koding/tools/log"
	"math/rand"
	"net"
	"os"
	"runtime"
	"time"
)

const MaxInt = int(^uint(0) >> 1)

var version string
var numClients int = 0
var ChangeNumClients chan int = make(chan int)
var ShuttingDown bool = false

func Startup(serviceName string, needRoot bool) {
	if needRoot && os.Getuid() != 0 {
		fmt.Println("Must be run as root.")
		os.Exit(1)
	}

	runtime.GOMAXPROCS(runtime.NumCPU())
	rand.Seed(time.Now().UnixNano())

	var profile string
	flag.StringVar(&profile, "c", "", "Configuration profile")
	flag.BoolVar(&log.LogDebug, "d", false, "Log debug messages")

	flag.Parse()
	if flag.NArg() != 0 {
		flag.PrintDefaults()
		os.Exit(1)
	}
	if profile == "" {
		fmt.Println("Please specify a configuration profile (-c).")
		flag.PrintDefaults()
		os.Exit(1)
	}

	config.LoadConfig(profile)

	log.Init(serviceName, profile)
	log.Info(fmt.Sprintf("Process '%v' started (version '%v').", serviceName, version))

	go func() {
		for {
			numClients += <-ChangeNumClients
			if ShuttingDown && numClients == 0 {
				log.Info("Shutdown complete. Terminating.")
				os.Exit(0)
			}
		}
	}()
}

func BeginShutdown() {
	ShuttingDown = true
	ChangeNumClients <- 0
	log.Info("Beginning shutdown.")
}

func RunStatusLogger() {
	go func() {
		for {
			if ShuttingDown {
				log.Info(fmt.Sprintf("Shutting down, still %d clients.", numClients), fmt.Sprintf("Number of goroutines: %d"))
			}
			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			log.Gauges(map[string]float64{
				"clients":    float64(numClients),
				"goroutines": float64(runtime.NumGoroutine()),
				"memory":     float64(m.Alloc),
			})
			time.Sleep(time.Duration(config.Current.Librato.Interval) * time.Millisecond)
		}
	}()
}

func RandomString() string {
	r := make([]byte, 128/8)
	cryptorand.Read(r)
	return base64.StdEncoding.EncodeToString(r)
}

func NewIntPool(offset int) (<-chan int, chan<- int) {
	fetchChan := make(chan int)
	releaseChan := make(chan int)
	go func() {
		next := offset
		tail := offset + 1
		unused := make([]int, 0)
		for {
			select {
			case fetchChan <- next:
				if len(unused) != 0 {
					next = unused[len(unused)-1]
					unused = unused[:len(unused)-1]
				} else {
					next = tail
					tail += 1
				}
			case i := <-releaseChan:
				unused = append(unused, i)
			}
		}
	}()
	return fetchChan, releaseChan
}

func IntToIP(v int) net.IP {
	ip := net.IPv4(0, 0, 0, 0)
	binary.BigEndian.PutUint32(ip[12:16], uint32(v))
	return ip
}

func IPToInt(ip net.IP) int {
	return int(binary.BigEndian.Uint32(ip[12:16]))
}
