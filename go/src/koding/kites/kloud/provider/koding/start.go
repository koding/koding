package koding

import (
	"errors"
	"koding/kites/kloud/machinestate"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
)

func (m *Machine) Start(ctx context.Context) error {
	if err := m.UpdateState("Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	if err := m.AlwaysOn(); err != nil {
		return err
	}

	if err := m.NetworkUsage(); err != nil {
		return err
	}

	if err := m.PlanState(); err != nil {
		return err
	}

	infoResp, err := m.Session.AWSClient.Info()
	if err != nil {
		return err
	}

	m.push("Starting machine", 10, machinestate.Starting)

	// check if the user has something else than their current instance type
	// and revert back to t2.micro. This is lazy auto healing of instances that
	// were created because there were no capacity for their specific instance
	// type.
	if infoResp.InstanceType != m.Meta.InstanceType {
		m.Log.Warning("instance is using '%s'. Changing back to '%s'",
			infoResp.InstanceType, m.Meta.InstanceType)

		opts := &ec2.ModifyInstance{InstanceType: instances[m.Meta.InstanceType].String()}

		if _, err := m.Session.AWSClient.Client.ModifyInstance(m.Meta.InstanceId, opts); err != nil {
			m.Log.Warning("couldn't change instance to '%s' again. err: %s",
				m.Meta.InstanceType, err)
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
			instance, err := m.Session.AWSClient.Start(ctx)
			if err == nil {
				m.IpAddress = instance.PublicIpAddress
				m.Meta.InstanceType = instance.InstanceType
				return nil
			}

			// check if the error is a 'InsufficientInstanceCapacity" error or
			// "InstanceLimitExceeded, if not return back because it's not a
			// resource or capacity problem.
			if !isCapacityError(err) {
				return err
			}

			m.Log.Error("IMPORTANT: %s", err)

			for _, instanceType := range InstancesList {
				m.Log.Warning("Fallback: starting again with using instance: %s instead of %s",
					instanceType, m.Meta.InstanceType)

				// now change the instance type before we start so we can
				// avoid the instance capacity problem
				opts := &ec2.ModifyInstance{InstanceType: instanceType}
				if _, err := m.Session.AWSClient.Client.ModifyInstance(m.Meta.InstanceId, opts); err != nil {
					return err
				}

				// just give a little time so it can be catched because EC2 is
				// eventuall consistent. Otherwise start might fail even if we
				// do the ModifyInstance call
				time.Sleep(time.Second * 2)

				instance, err = m.Session.AWSClient.Start(ctx)
				if err == nil {
					m.IpAddress = instance.PublicIpAddress
					m.Meta.InstanceType = instance.InstanceType
					return nil
				}

				m.Log.Warning("Fallback: couldn't start instance with type: '%s'. err: %s ",
					instanceType, err)
			}

			return errors.New("no other instances are available")
		}

		// go go go!
		if err := startFunc(); err != nil {
			return err
		}
	}

	// Assign a Elastic IP for a paying customer if it doesn't have any
	// assigned yet (Elastic IP's are assigned only during the Build). We
	// lookup the IP from the Elastic IPs, if it's not available (returns an
	// error) we proceed and create it.
	if m.Payment.Plan != Free { // check this first to avoid an additional AWS call
		_, err = m.Session.AWSClient.Client.Addresses([]string{m.IpAddress}, nil, ec2.NewFilter())
		if isAddressNotFoundError(err) {
			m.Log.Debug("Paying user detected, Creating an Public Elastic IP")

			elasticIp, err := m.Session.AWSClient.AllocateAndAssociateIP(m.Meta.InstanceId)
			if err != nil {
				m.Log.Warning("couldn't not create elastic IP: %s", err)
			} else {
				m.IpAddress = elasticIp
			}
		}
	}

	m.push("Initializing domain instance", 65, machinestate.Starting)
	if err := m.UpdateDomain(m.Domain, m.Username); err != nil {
		m.Log.Error("updating domains for starting err: %s", err.Error())
	}

	// also get all domain aliases that belongs to this machine and unset
	m.push("Updating domain aliases", 80, machinestate.Starting)
	domains, err := m.DomainsById()
	if err != nil {
		m.Log.Error("fetching domains for starting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.UpdateDomain(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update domain: %s", err.Error())
		}
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	m.checkKite()

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.Id,
			bson.M{"$set": bson.M{
				"ipAddress":         m.IpAddress,
				"meta.instanceName": m.Meta.InstanceName,
				"meta.instanceId":   m.Meta.InstanceId,
				"meta.instanceType": m.Meta.InstanceType,
				"status.state":      machinestate.Running.String(),
				"status.modifiedAt": time.Now().UTC(),
				"status.reason":     "Machine is running",
			}},
		)
	})
}
