package controller

import "github.com/koding/logging"

type Controller struct {
	log logging.Logger
}

func New(log logging.Logger) (*Controller, error) {
	wc := &Controller{
		log: log,
	}

	return wc, nil
}

func (mwc *Controller) Start() {
	mwc.migrateAllAccountsToAlgolia()
}
