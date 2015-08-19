package main

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"net/http"
	"socialapi/workers/email/emailsender"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
)

type GatherStat struct {
	log        logging.Logger
	dog        *metrics.DogStatsD
	redis      *redis.RedisSession
	kiteClient *kite.Client
}

type kloudRequestArgs struct {
	MachineId string `json:"machineId"`
	Reason    string `json:"reason"`
	Provider  string `json:"provider"`
}

func (g *GatherStat) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	var req = models.NewGatherStat()
	if err := json.NewDecoder(r.Body).Decode(req); err != nil {
		write404Err(g.log, err, w)
		return
	}

	if r != nil {
		defer r.Body.Close()
	}

	if err := g.save(req); err != nil {
		write500Err(g.log, err, w)
		return
	}

	if err := g.stopVMIfAbusive(req); err != nil {
		write500Err(g.log, err, w)
		return
	}

	w.WriteHeader(200)
}

func (g *GatherStat) save(s *models.GatherStat) error {
	if err := modelhelper.SaveGatherStat(s); err != nil {
		return err
	}

	for _, stat := range s.Stats {
		name := fmt.Sprintf("gather:stats:%s", stat.Name)
		tags := []string{"username:" + s.Username, "env" + s.Env}

		var value float64

		switch stat.Value.(type) {
		case int:
			value = float64(stat.Value.(int))
		case float64:
			value = stat.Value.(float64)
		default:
			continue
		}

		// name, value, tags, rate
		if err := g.dog.Gauge(name, value, tags, 1.0); err != nil {
			g.log.Error("Sending to datadog failed: %s", err)
			continue
		}
	}

	return nil
}

// stopVMIfAbusive stops VM if user is abusive, but only if user
// isn't exempt from being stopped
func (g *GatherStat) stopVMIfAbusive(s *models.GatherStat) error {
	isExempt, err := g.isUserExempt(s.Username)
	if err != nil {
		return err
	}

	if g.shouldStop(s) && !isExempt {
		if err := g.notifyUser(s.Username); err != nil {
			return err
		}

		return g.stopVMs(s.Username)
	}

	return nil
}

// notifyUser sends an email to user alerting abuse has been found
// in their VMs.
func (g *GatherStat) notifyUser(username string) error {
	user, err := modelhelper.GetUser(username)
	if err != nil {
		return err
	}

	mail := &emailsender.Mail{
		To:      user.Email,
		Subject: DefaultReason,
		Properties: &emailsender.Properties{
			Username: DefaultReason,
			Options:  map[string]interface{}{},
		},
	}

	return emailsender.Send(mail)
}

// shouldStop returns if machine should be stopped or not. Abuse type
// of stat is only sent when there's abuse.
func (g *GatherStat) shouldStop(s *models.GatherStat) bool {
	return s.Type == models.GatherStatAbuse && g.globalStopEnabled()
}

// globalStopEnabled is a lock to enable/disable stopping of VMs.
func (g *GatherStat) globalStopEnabled() bool {
	return !g.redis.Exists(GlobalDisableKey)
}

// isUserExempt checks if user is exempt from having their machines.
func (g *GatherStat) isUserExempt(username string) (bool, error) {
	isEmployee, err := isKodingEmployee(username)
	if err != nil {
		return false, err
	}

	if isEmployee {
		return true, nil
	}

	return isInExemptList(g.redis, username)
}

func (g *GatherStat) stopVMs(username string) error {
	machines, err := modelhelper.GetMachinesByUsername(username)
	if err != nil {
		return err
	}

	for _, machine := range machines {
		if g.kiteClient == nil {
			g.log.Info("KloudClient not initialized. Not stopping: %s", machine.ObjectId)
			return nil
		}

		if machine.Status.State != "Running" {
			g.log.Info("Machine: '%s' has status: '%s'...skipping", machine.ObjectId, machine.Status.State)
			return nil
		}

		g.log.Info("Starting to stop machine: '%s' for username: '%s'", machine.ObjectId, username)

		if g.kiteClient == nil {
			g.log.Debug("Kite Client required to stop machaine...skipping")
			continue
		}

		_, err = g.kiteClient.TellWithTimeout("stop", KloudTimeout, &kloudRequestArgs{
			MachineId: machine.ObjectId.Hex(),
			Reason:    DefaultReason,
			Provider:  KodingProvider,
		})

		if err != nil {
			g.log.Info("Failed to stop machine: '%s' for username: '%s' due to: %s", machine.ObjectId, username, err)
		}
	}

	return nil
}
