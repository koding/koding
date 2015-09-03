package main

import (
	"encoding/json"
	"fmt"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kodingutils"
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

	if err := g.blockUserIfAbusve(req); err != nil {
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

// blockUserIfAbusve stops VM if user is abusive, but only if user
// isn't exempt from being stopped
func (g *GatherStat) blockUserIfAbusve(s *models.GatherStat) error {
	shouldBlock, err := g.shouldBlock(s)
	if err != nil {
		return err
	}

	if shouldBlock {
		if err := g.notifyUser(s.Username); err != nil {
			return err
		}

		return kodingutils.BlockUser(g.kiteClient, s.Username, DefaultReason, BlockDuration)
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
			Username: user.Name,
			Options:  map[string]interface{}{},
		},
	}

	return emailsender.Send(mail)
}

// shouldBlock returns if user should be stopped or not depending on
// abuse is found in their VM.
func (g *GatherStat) shouldBlock(s *models.GatherStat) (bool, error) {
	isExempt, err := g.isUserExempt(s.Username)
	if err != nil {
		return false, err
	}

	if isExempt {
		return false, nil
	}

	if g.globalBlockDisabled() {
		return false, nil
	}

	if s.Type != models.GatherStatAbuse {
		return false, nil
	}

	return true, nil
}

// globalBlockEnabled is a lock to enable/disable stopping of VMs.
func (g *GatherStat) globalBlockDisabled() bool {
	return g.redis.Exists(GlobalDisableKey)
}

// isUserExempt checks if user is exempt from having their machines.
func (g *GatherStat) isUserExempt(username string) (bool, error) {
	isEmployee, err := kodingutils.IsKodingEmployee(username)
	if err != nil {
		return false, err
	}

	if isEmployee {
		return true, nil
	}

	return isInExemptList(g.redis, username)
}
