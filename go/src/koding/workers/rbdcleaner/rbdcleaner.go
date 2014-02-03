package main

import (
	"bytes"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/tools/logger"
	"os/exec"
	"strings"
	"time"
	"labix.org/v2/mgo"

	"github.com/fatih/set"
	"github.com/op/go-logging"
)

var (
	log      = logger.New("rbd-cleaner")
	interval = time.Minute * 30
)

func main() {
	logging.SetLevel(logging.INFO, "rbd-cleaner")
	log.Info("starting rbd-cleaner")
	log.Info("interval set to %s", interval)

	// first start
	err := rbdCleaner()
	if err != nil {
		log.Error(err.Error())
	}

	// and then for every other intervals
	for _ = range time.Tick(interval) {
		err := rbdCleaner()
		if err != nil {
			log.Error(err.Error())
		}
	}
}

func rbdCleaner() error {
	s, err := rbdList()
	if err != nil {
		return err
	}

	log.Info("cleaner started. going to iterate over %d images in 'vms' pool.", s.Size())
	cleanCount := 0
	errCount := 0
	s.Each(func(rbdName interface{}) bool {
		vmName := rbdName.(string)
		vmId := strings.TrimPrefix(vmName, "vm-")
		vm := new(models.VM)

		err := mongodb.One("jVMs", vmId, vm)
		if err == nil {
			return true //  rbd image does exists in jVMS, don't touch it and continue
		}

		if err != mgo.ErrNotFound {
			log.Error("MongoDB lookup err: %s", err.Error())
			return true
		}

		log.Info("Removing image '%s' from rbd", vmName)
		res, err := removeRBDImage(vmName)
		if err != nil {
			errCount++
			log.Error("err removing '%s'\n", err)
			return true
		}

		cleanCount++
		log.Info("%s", res)
		return true
	})
	log.Info("cleaner ended. images cleaned: %d images with err: %d", cleanCount, errCount)

	return nil
}

func removeRBDImage(imageName string) (string, error) {
	out, err := exec.Command("/usr/bin/rbd", "rm", "vms/"+imageName).CombinedOutput()
	if err != nil {
		return "", err
	}

	return strings.TrimSpace(string(out)), nil
}

func rbdList() (*set.Set, error) {
	s := set.New()
	out, err := exec.Command("/usr/bin/rbd", "ls", "vms").CombinedOutput()
	if err != nil {
		return nil, err
	}

	rbds := string(bytes.TrimSpace(out))
	for _, r := range strings.Split(rbds, "\n") {
		s.Add(r)
	}
	return s, nil
}
