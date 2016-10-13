package main

import (
	"bytes"
	"flag"
	"koding/db/models"
	"koding/db/mongodb"
	"koding/tools/config"
	"koding/tools/logger"
	"os/exec"
	"strings"
	"time"

	"gopkg.in/mgo.v2"

	"gopkg.in/fatih/set.v0"
)

var (
	log         = logger.New("rbd-cleaner")
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagtimer   = flag.String("i", "30m", "Configuration profile from file")
	mongo       *mongodb.MongoDB
)

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}

	interval, err := time.ParseDuration(*flagtimer)
	if err != nil {
		log.Fatal(err.Error())
	}

	conf := config.MustConfig(*flagProfile)
	mongo = mongodb.NewMongoDB(conf.Mongo)

	log.SetLevel(logger.INFO)
	log.Info("starting rbd-cleaner")
	log.Info("interval set to %s", interval)

	// first start
	err = rbdCleaner()
	if err != nil {
		log.Error(err.Error())
	}

	// and then for every other intervals
	for range time.Tick(interval) {
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

		err := mongo.One("jVMs", vmId, vm)
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
