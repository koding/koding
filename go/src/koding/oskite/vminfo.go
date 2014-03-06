package oskite

import (
	"fmt"
	"koding/tools/kite"
	"koding/tools/utils"
	"koding/virt"
	"math/rand"
	"sync"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

var (
	// stores vm based mutexes
	infos      = make(map[bson.ObjectId]*VMInfo)
	infosMutex sync.Mutex
)

// VMInfo stores information about a given VM. Each client's VM is associated
// with a VMInfo. It's also used for protecting multiple calls to a single VM.
type VMInfo struct {
	vm              *virt.VM
	useCounter      int
	timeout         *time.Timer
	mutex           sync.Mutex
	totalCpuUsage   int
	currentCpus     []string
	currentHostname string

	State               string `json:"state"`
	CpuUsage            int    `json:"cpuUsage"`
	CpuShares           int    `json:"cpuShares"`
	MemoryUsage         int    `json:"memoryUsage"`
	PhysicalMemoryLimit int    `json:"physicalMemoryLimit"`
	TotalMemoryLimit    int    `json:"totalMemoryLimit"`
}

// newInfo returns a new VMInfo struct
func newInfo(vm *virt.VM) *VMInfo {
	return &VMInfo{
		vm:                  vm,
		useCounter:          0,
		timeout:             time.NewTimer(0),
		totalCpuUsage:       utils.MaxInt,
		currentCpus:         nil,
		currentHostname:     vm.HostnameAlias,
		CpuShares:           1000,
		PhysicalMemoryLimit: 100 * 1024 * 1024,
		TotalMemoryLimit:    1024 * 1024 * 1024,
	}
}

// getInfo returns an existing VMInfo struct. It creates a new instance if an
// info doesn't exist for the given VM.
func getInfo(vm *virt.VM) *VMInfo {
	var info *VMInfo
	var found bool

	infosMutex.Lock()
	info, found = infos[vm.Id]
	if !found {
		info = newInfo(vm)
		infos[vm.Id] = info
	}
	infosMutex.Unlock()

	return info
}

// stopTimeout stops the timer for every incoming request for the given
// channel. That whay we prevent that the VM is turned off after the timeout.
func (v *VMInfo) stopTimeout(channel *kite.Channel) {
	if channel != nil {
		return
	}

	v.useCounter += 1
	v.timeout.Stop()

	channel.KiteData = v
	channel.OnDisconnect(func() {
		v.mutex.Lock()
		defer v.mutex.Unlock()

		v.useCounter -= 1
		v.startTimeout()
	})
}

// startTimeout starts the turn off timer for the VM that is associated with
// the info instance. It does return if the VM is Always On.
func (v *VMInfo) startTimeout() {
	if v.useCounter != 0 || v.vm.AlwaysOn {
		return
	}

	// Shut down the VM (unprepareVM does it.) The timeout is calculated as:
	// * 5  Minutes from kite.go
	// * 50 Minutes pre-defined timeout
	// * 5  Minutes after we give warning
	// * [0, 30] random duration to avoid hickups during mass unprepares
	// In Total it's [60, 90] minutes.
	totalTimeout := vmTimeout + randomMinutes(30)
	log.Info("Timer is started. VM %s will be shut down in %s minutes",
		v.vm.Id.Hex(), totalTimeout)

	v.timeout = time.AfterFunc(totalTimeout, func() {
		if v.useCounter != 0 || v.vm.AlwaysOn {
			return
		}

		if v.vm.GetState() == "RUNNING" {
			if err := v.vm.SendMessageToVMUsers("========================================\nThis VM will be turned off in 5 minutes.\nLog in to Koding.com to keep it running.\n========================================\n"); err != nil {
				log.Warning("%v", err)
			}
		}

		v.timeout = time.AfterFunc(5*time.Minute, func() {
			v.mutex.Lock()
			defer v.mutex.Unlock()
			if v.useCounter != 0 || v.vm.AlwaysOn {
				return
			}

			prepareQueue <- &QueueJob{
				msg: "vm unprepare " + v.vm.HostnameAlias,
				f: func() (string, error) {
					// mutex is needed because it's handled in the queue
					v.mutex.Lock()
					defer v.mutex.Unlock()

					v.unprepareVM()
					return fmt.Sprintf("shutting down %s after %s", v.vm.Id.Hex(), totalTimeout), nil
				},
			}

		})
	})
}

func (v *VMInfo) unprepareVM() {
	if err := virt.UnprepareVM(v.vm.Id); err != nil {
		log.Warning("%v", err)
	}

	if err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"_id": v.vm.Id}, bson.M{"$set": bson.M{"hostKite": nil}})
	}); err != nil {
		log.LogError(err, 0, v.vm.Id.Hex())
	}

	infosMutex.Lock()
	if v.useCounter == 0 {
		delete(infos, v.vm.Id)
	}
	infosMutex.Unlock()
}

// randomMinutes returns a random duration between [0,n] in minutes. It panics if n <=  0.
func randomMinutes(n int64) time.Duration { return time.Minute * time.Duration(rand.Int63n(n)) }
