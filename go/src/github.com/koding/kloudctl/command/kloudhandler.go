package command

import (
	"errors"
	"fmt"
	"math/rand"
	"strconv"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
)

func init() {
	rand.Seed(time.Now().UTC().UnixNano())
}

type Actioner interface {
	Action([]string, *kite.Client) error
}

type ActionFunc func(args []string, k *kite.Client) error

func (a ActionFunc) Action(args []string, k *kite.Client) error {
	return a(args, k)
}

func kloudWrapper(args []string, actioner Actioner) error {
	k, err := kloudClient()
	if err != nil {
		DefaultUi.Error(err.Error())
		return err
	}

	err = actioner.Action(args, k)
	if err != nil {
		DefaultUi.Error(err.Error())
		return err
	}

	return nil

}

func kloudClient() (*kite.Client, error) {
	k := kite.New("kloudctl", "0.0.1")
	config, err := config.Get()
	if err != nil {
		return nil, err
	}

	k.Config = config
	k.SetLogLevel(kite.WARNING)

	query, err := protocol.KiteFromString(flagKloudQuery + "////")
	if err != nil {
		return nil, err
	}

	kloudQuery := protocol.KontrolQuery{
		Username:    query.Username,
		ID:          query.ID,
		Hostname:    query.Hostname,
		Name:        query.Name,
		Environment: query.Environment,
		Region:      query.Region,
		Version:     query.Version,
	}

	kites, err := k.GetKites(kloudQuery)
	if err != nil {
		return nil, err
	}

	remoteKite := func(index int) (*kite.Client, error) {
		if index == 0 {
			return nil, errors.New("zero index")
		}

		remoteKloud := kites[index-1]
		if err := remoteKloud.Dial(); err != nil {
			return nil, err
		}

		return remoteKloud, nil
	}

	if len(kites) == 1 {
		return remoteKite(1)
	}

	if flagRandomKite {
		randomIndex := rand.Intn(len(kites)) + 1
		DefaultUi.Output(fmt.Sprintf("Using random kite %s", kites[randomIndex-1]))
		return remoteKite(randomIndex)
	}

	// we have more than one kloud instance
	DefaultUi.Output("Which kloud instance do you want to use?\n")
	for i, kite := range kites {
		fmt.Printf("[%d]\t %+v\n", i+1, kite)
	}

	response, err := DefaultUi.Ask("\n==> ")
	if err != nil {
		return nil, err
	}

	index, err := strconv.Atoi(response)
	if err != nil {
		return nil, err
	}

	if index > len(kites) || index == 0 {
		return nil, errors.New("Invalid input")
	}

	return remoteKite(index)
}
