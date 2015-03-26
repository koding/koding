package oldkoding

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"koding/db/mongodb"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/dnsclient"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/multiec2"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/mitchellh/goamz/ec2"
)

const (
	ProviderName = "koding"
)

type pushValues struct {
	Start, Finish int
}

// Provider implements the kloud packages Storage, Builder and Controller
// interface
type Provider struct {
	Kite *kite.Kite
	Log  logging.Logger
	Push func(string, int, machinestate.State)

	// DB reference
	Session       *mongodb.MongoDB
	DomainStorage protocol.DomainStorage

	// A flag saying if user permissions should be ignored
	// store negation so default value is aligned with most common use case
	Test bool

	// AWS related references and settings
	EC2Clients *multiec2.Clients
	DNS        *dnsclient.DNS
	Bucket     *Bucket

	KontrolURL        string
	KontrolPrivateKey string
	KontrolPublicKey  string

	// If available a key pair with the given public key and name should be
	// deployed to the machine, the corresponding PrivateKey should be returned
	// in the ProviderArtifact. Some providers such as Amazon creates
	// publicKey's on the fly and generates the privateKey themself.
	PublicKey  string `structure:"publicKey"`
	PrivateKey string `structure:"privateKey"`
	KeyName    string `structure:"keyName"`

	// A set of connected, ready to use klients
	KlientPool *klient.KlientPool

	// A set of machines that defines machines who's klient kites are not
	// running. The timer is used to stop the machines after 30 minutes
	// inactivity.
	InactiveMachines   map[string]*time.Timer
	InactiveMachinesMu sync.Mutex

	Stats *metrics.DogStatsD

	// Fetcher is used to fetch a machines plan
	Fetcher Fetcher

	// NetworkUsageEndpoint is used to fetch a machines network usage
	NetworkUsageEndpoint string
}

func (p *Provider) NewClient(m *protocol.Machine) (*amazon.Amazon, error) {
	// userLog := p.Log.New(m.Id)
	// a := &amazon.AmazonClient{
	// 	Log: userLog,
	// 	Push: func(msg string, percentage int, state machinestate.State) {
	// 		userLog.Debug("%s (username: %s)", msg, m.Username)
	//
	// 		m.Eventer.Push(&eventer.Event{
	// 			Message:    msg,
	// 			Status:     state,
	// 			Percentage: percentage,
	// 		})
	// 	},
	// 	// Metrics: p.Stats,
	// }

	// var err error

	// we pass a nil client just to fill the Builder data. The reason for that
	// is to retrieve the `region` of a user so we can create a client based on
	// the region below.
	a, err := amazon.New(m.Builder, nil)
	if err != nil {
		return nil, fmt.Errorf("koding-amazon err: %s", err)
	}

	if a.Builder.Region == "" {
		a.Builder.Region = "us-east-1"
		p.Log.Critical("region is not set in. Fallback to us-east-1.")
	}

	client, err := p.EC2Clients.Region(a.Builder.Region)
	if err != nil {
		return nil, err
	}

	a.Client = client

	// needed to deploy during build
	a.Builder.KeyPair = p.KeyName

	// needed to create the keypair if it doesn't exist
	a.Builder.PublicKey = p.PublicKey
	a.Builder.PrivateKey = p.PrivateKey
	return a, nil
}

func (p *Provider) PlanChecker(m *protocol.Machine) (*PlanChecker, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	if p.Fetcher == nil {
		return nil, errors.New("Fetcher is not initialized")
	}

	// check current plan
	fetcherResp, err := p.Fetcher.Fetch(m)
	if err != nil {
		return nil, err
	}

	return &PlanChecker{
		Api:      a,
		Provider: p,
		DB:       p.Session,
		Kite:     p.Kite,
		Log:      p.Log,
		Username: m.Username,
		Machine:  m,
		Plan:     fetcherResp,
	}, nil
}

func (p *Provider) Start(m *protocol.Machine) (*protocol.Artifact, error) {
	checker, err := p.PlanChecker(m)
	if err != nil {
		return nil, err
	}

	if err := checker.AlwaysOn(); err != nil {
		return nil, err
	}

	if err := checker.NetworkUsage(); err != nil {
		return nil, err
	}

	if err := checker.PlanState(); err != nil {
		return nil, err
	}

	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	infoResp, err := a.Info()
	if err != nil {
		return nil, err
	}

	artifact := &protocol.Artifact{
		IpAddress:  m.IpAddress,
		InstanceId: a.Builder.InstanceId,
	}

	// stop the timer and remove it from the list of inactive machines so it
	// doesn't get called later again.
	p.stopTimer(m)

	a.Push("Starting machine", 10, machinestate.Starting)

	// check if the user has something else than their current instance type
	// and revert back to t2.micro. This is lazy auto healing of instances that
	// were created because there were no capacity for their specific instance
	// type.
	if infoResp.InstanceType != a.Builder.InstanceType {
		p.Log.Warning("instance is using '%s'. Changing back to '%s'",
			infoResp.InstanceType, a.Builder.InstanceType)

		opts := &ec2.ModifyInstance{InstanceType: instances[a.Builder.InstanceType].String()}

		if _, err := a.Client.ModifyInstance(a.Builder.InstanceId, opts); err != nil {
			p.Log.Warning("couldn't change instance to '%s' again. err: %s",
				a.Builder.InstanceType, err)
		}

		// Because of AWS's eventually consistency state, we wait to get the
		// final and correct answer.
		time.Sleep(time.Second * 2)
	}

	// only start if the machine is stopped, stopping
	if infoResp.State.In(machinestate.Stopped, machinestate.Stopping) {
		// Give time until it's being stopped
		if infoResp.State == machinestate.Stopping {
			time.Sleep(time.Second * 20)
		}

		startFunc := func() error {
			artifact, err = a.Start(true)
			if err == nil {
				return nil
			}

			// check if the error is a 'InsufficientInstanceCapacity" error or
			// "InstanceLimitExceeded, if not return back because it's not a
			// resource or capacity problem.
			if !isCapacityError(err) {
				return err
			}

			p.Log.Error("IMPORTANT: %s", err)

			for _, instanceType := range InstancesList {
				p.Log.Warning("Fallback: starting again with using instance: %s instead of %s",
					instanceType, a.Builder.InstanceType)

				// now change the instance type before we start so we can
				// avoid the instance capacity problem
				opts := &ec2.ModifyInstance{InstanceType: instanceType}
				if _, err := a.Client.ModifyInstance(a.Builder.InstanceId, opts); err != nil {
					return err
				}

				// just give a little time so it can be catched because EC2 is
				// eventuall consistent. Otherwise start might fail even if we
				// do the ModifyInstance call
				time.Sleep(time.Second * 2)

				artifact, err = a.Start(true)
				if err == nil {
					return nil
				}

				p.Log.Warning("Fallback: couldn't start instance with type: '%s'. err: %s ",
					instanceType, err)
			}

			return errors.New("no other instances are available")
		}

		// go go go!
		if err := startFunc(); err != nil {
			return nil, err
		}
	}

	// Assign a Elastic IP for a paying customer if it doesn't have any
	// assigned yet (Elastic IP's are assigned only during the Build). We
	// lookup the IP from the Elastic IPs, if it's not available (returns an
	// error) we proceed and create it.
	if checker.Plan.Plan != Free { // check this first to avoid an additional AWS call
		_, err = a.Client.Addresses([]string{artifact.IpAddress}, nil, ec2.NewFilter())
		if isAddressNotFoundError(err) {
			p.Log.Debug("Paying user detected, Creating an Public Elastic IP")

			elasticIp, err := allocateAndAssociateIP(a.Client, artifact.InstanceId)
			if err != nil {
				p.Log.Warning("couldn't not create elastic IP: %s", err)
			} else {
				artifact.IpAddress = elasticIp
			}
		}
	}

	// update the intermediate information
	p.Update(m.Id, &kloud.StorageData{
		Type: "starting",
		Data: map[string]interface{}{
			"ipAddress": artifact.IpAddress,
		},
	})

	a.Push("Initializing domain instance", 65, machinestate.Starting)
	if err := p.UpdateDomain(artifact.IpAddress, m.Domain.Name, m.Username); err != nil {
		p.Log.Error("updating domains for starting err: %s", err.Error())
	}

	// also get all domain aliases that belongs to this machine and unset
	a.Push("Updating domain aliases", 80, machinestate.Starting)
	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("fetching domains for starting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := p.UpdateDomain(artifact.IpAddress, domain.Name, m.Username); err != nil {
			p.Log.Error("couldn't update domain: %s", err.Error())
		}
	}

	artifact.DomainName = m.Domain.Name

	a.Push("Checking remote machine", 90, machinestate.Starting)
	if p.IsKlientReady(m.QueryString) {
		p.Log.Debug("klient is ready.")
	} else {
		p.Log.Warning("klient is not ready. I couldn't connect to it.")
	}

	return artifact, nil
}

func (p *Provider) Stop(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	// stop the timer and remove it from the list of inactive machines so it
	// doesn't get called later again.
	p.stopTimer(m)

	err = a.Stop(true)
	if err != nil {
		return err
	}

	a.Push("Initializing domain instance", 65, machinestate.Stopping)
	if err := p.DNS.Validate(m.Domain.Name, m.Username); err != nil {
		return err
	}

	a.Push("Deleting domain", 85, machinestate.Stopping)
	if err := p.DNS.Delete(m.Domain.Name); err != nil {
		p.Log.Warning("couldn't delete domain %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("fetching domains for unseting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := p.DNS.Delete(domain.Name); err != nil {
			p.Log.Error("couldn't delete domain: %s", err.Error())
		}
	}

	return nil
}

func (p *Provider) Restart(m *protocol.Machine) error {
	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	return a.Restart(false)
}

func (p *Provider) Reinit(m *protocol.Machine) (*protocol.Artifact, error) {
	a, err := p.NewClient(m)
	if err != nil {
		return nil, err
	}

	if err := p.destroy(a, m, &pushValues{Start: 10, Finish: 40}); err != nil {
		return nil, err
	}

	// clean up old data, so if build fails below at least we give the chance to build it again
	p.Update(m.Id, &kloud.StorageData{
		Type: "building",
		Data: map[string]interface{}{
			"instanceId":   "",
			"ipAddress":    "",
			"instanceName": "",
			"queryString":  "",
		},
	})
	p.UpdateState(m.Id, "Reinit cleanup", machinestate.NotInitialized)

	// cleanup this too so "build" can continue with a clean setup
	a.Builder.InstanceId = ""
	m.QueryString = ""
	m.IpAddress = ""

	if p.Fetcher == nil {
		return nil, errors.New("Fetcher is not initialized")
	}

	// check current plan
	fetcherResp, err := p.Fetcher.Fetch(m)
	if err != nil {
		return nil, err
	}

	checker := &PlanChecker{
		Api:      a,
		Provider: p,
		DB:       p.Session,
		Kite:     p.Kite,
		Log:      p.Log,
		Username: m.Username,
		Machine:  m,
		Plan:     fetcherResp,
	}

	b := &Build{
		amazon:     a,
		machine:    m,
		provider:   p,
		plan:       fetcherResp.Plan,
		checker:    checker,
		start:      40,
		finish:     90,
		log:        p.Log,
		cleanFuncs: make([]func(), 0),
	}

	// this updates/creates domain
	return b.run()
}

func (p *Provider) Destroy(m *protocol.Machine) error {
	if m.State == machinestate.NotInitialized {
		return nil
	}

	a, err := p.NewClient(m)
	if err != nil {
		return err
	}

	if err := p.destroy(a, m, &pushValues{Start: 10, Finish: 80}); err != nil {
		return err
	}

	domains, err := p.DomainStorage.GetByMachine(m.Id)
	if err != nil {
		p.Log.Error("fetching domains for unseting err: %s", err.Error())
	}

	a.Push("Deleting base domain", 85, machinestate.Terminating)
	if err := p.DNS.Delete(m.Domain.Name); err != nil {
		// if it's already deleted, for example because of a STOP, than we just
		// log it here instead of returning the error
		p.Log.Error("deleting domain during destroying err: %s", err.Error())
	}

	a.Push("Deleting custom domain", 90, machinestate.Terminating)
	for _, domain := range domains {
		if err := p.DNS.Delete(domain.Name); err != nil {
			p.Log.Error("couldn't delete domain: %s", err.Error())
		}

		if err := p.DomainStorage.UpdateMachine(domain.Name, ""); err != nil {
			p.Log.Error("couldn't unset machine domain: %s", err.Error())
		}
	}

	// try to release/delete a public elastic IP, if there is an error we don't
	// care (the instance might not have an elastic IP, aka a free user.
	if resp, err := a.Client.Addresses([]string{m.IpAddress}, nil, ec2.NewFilter()); err == nil {
		if len(resp.Addresses) == 0 {
			return nil // nothing to do
		}

		address := resp.Addresses[0]
		p.Log.Debug("Got an elastic IP %+v. Going to relaease it", address)

		a.Client.ReleaseAddress(address.AllocationId)
	}
	return nil
}

func (p *Provider) destroy(a *amazon.AmazonClient, m *protocol.Machine, v *pushValues) error {
	// stop the timer and remove it from the list of inactive machines so it
	// doesn't get called later again.
	p.stopTimer(m)

	// means if final is 40 our destroy method below will be push at most up to
	// 32.
	middleVal := float64(v.Finish) * (8.0 / 10.0)
	return a.Destroy(v.Start, int(middleVal))
}

// stopTimer stops the inactive timeout timer for the given queryString
func (p *Provider) stopTimer(m *protocol.Machine) {
	// stop the timer and remove it from the list of inactive machines so it
	// doesn't get called later again.
	p.InactiveMachinesMu.Lock()
	if timer, ok := p.InactiveMachines[m.QueryString]; ok {
		p.Log.Info("stopping inactive machine timer %s", m.QueryString)
		timer.Stop()
		p.InactiveMachines[m.QueryString] = nil // garbage collect
		delete(p.InactiveMachines, m.QueryString)
	}
	p.InactiveMachinesMu.Unlock()
}

// startTimer starts the inactive timeout timer for the given queryString. It
// stops the machine after 30 minutes.
func (p *Provider) startTimer(curMachine *protocol.Machine) {
	if a, ok := curMachine.Builder["alwaysOn"]; ok {
		if isAlwaysOn, ok := a.(bool); ok && isAlwaysOn {
			return // don't stop if alwaysOn is enabled
		}
	}

	p.InactiveMachinesMu.Lock()
	_, ok := p.InactiveMachines[curMachine.QueryString]
	p.InactiveMachinesMu.Unlock()
	if ok {
		// just return, because it's already in the map so it will be expired
		// with the function below
		return
	}

	p.Log.Info("[%s] klient is not running (username: %s), adding to list of inactive machines.",
		curMachine.Id, curMachine.Username)

	stopAfter := time.Minute * 30

	// wrap it so we can return errors and log them
	stopFunc := func(id string) error {
		// fetch it again so we have always the latest data. This is important
		// because another kloud instance might already stopped or we have
		// again a connection to klient
		m, err := p.Get(id)
		if err != nil {
			return err
		}

		// add fake eventer to avoid panic errors on NewClient at provider
		m.Eventer = &eventer.Events{}

		a, err := p.NewClient(m)
		if err != nil {
			return err
		}

		p.Log.Info("30 minutes passed. Rechecking again before I stop the machine (username: %s)", m.Username)

		infoResp, err := a.Info()
		if err != nil {
			return err
		}

		if infoResp.State.InProgress() {
			return fmt.Errorf("machine is in progress of '%s'", infoResp.State)
		}

		if infoResp.State == machinestate.Stopped {
			p.Log.Info("stop timer aborting. Machine is already stopped (username: %s)", m.Username)
			return errors.New("machine is already stopped")
		}

		if infoResp.State == machinestate.Running {
			err := klient.Exists(p.Kite, m.QueryString)
			if err == nil {
				p.Log.Info("stop timer aborting. Klient is already running (username: %s)", m.Username)
				return errors.New("we have a klient connection")
			}
		}

		p.Lock(m.Id)
		defer p.Unlock(m.Id)

		// mark our state as stopping so others know what we are doing
		stoppingReason := "Stopping process started due not active klient after 30 minutes waiting."
		p.UpdateState(m.Id, stoppingReason, machinestate.Stopping)

		p.Log.Info("Stopping machine (username: %s) after 30 minutes klient disconnection.",
			m.Id, m.Username)

		// Hasta la vista, baby!
		if err := p.Stop(m); err != nil {
			p.Log.Warning("could not stop ghost machine %s", err)
		}

		// update to final state too
		stopReason := "Stopping due not active and unreachable klient after 30 minutes waiting."
		p.UpdateState(m.Id, stopReason, machinestate.Stopped)

		// we don't need it anymore
		p.InactiveMachinesMu.Lock()
		delete(p.InactiveMachines, m.QueryString)
		p.InactiveMachinesMu.Unlock()

		return nil
	}

	p.InactiveMachines[curMachine.QueryString] = time.AfterFunc(stopAfter, func() {
		if err := stopFunc(curMachine.Id); err != nil {
			p.Log.Error("[%s] inactive klient stopper err: %s", curMachine.Id, err)
		}
	})
}
