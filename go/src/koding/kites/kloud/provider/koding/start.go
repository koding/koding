package koding

import (
	"errors"
	"fmt"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/mitchellh/goamz/ec2"
	"golang.org/x/net/context"
)

func (m *Machine) Start(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	// update the state to intiial state if something goes wrong, we are going
	// to change latestate to a more safe state if we passed a certain step
	// below
	latestState := m.State()
	defer func() {
		if err != nil {
			m.UpdateState("Machine is marked as "+latestState.String(), latestState)
		}
	}()

	if err := m.Checker.AlwaysOn(m.Username); err != nil {
		return err
	}

	if err := m.Checker.NetworkUsage(m.Username); err != nil {
		return err
	}

	if strings.ToLower(m.Payment.State) == "expired" {
		return fmt.Errorf("[%s] Plan is expired", m.Id.Hex())
	}

	instance, err := m.Session.AWSClient.Instance()
	if err != nil {
		return err
	}

	m.push("Starting machine", 10, machinestate.Starting)

	// check if the user has something else than their current instance type
	// and revert back to t2.micro. This is lazy auto healing of instances that
	// were created because there were no capacity for their specific instance
	// type.
	if instance.InstanceType != m.Meta.InstanceType {
		m.Log.Warning("instance is using '%s'. Changing back to '%s'",
			instance.InstanceType, m.Meta.InstanceType)

		opts := &ec2.ModifyInstance{InstanceType: plans.Instances[m.Meta.InstanceType].String()}
		if _, err := m.Session.AWSClient.Client.ModifyInstance(m.Meta.InstanceId, opts); err != nil {
			m.Log.Warning("couldn't change instance to '%s' again. err: %s",
				m.Meta.InstanceType, err)
		}

		// Because of AWS's eventually consistency state, we wait for maximum
		// three minutes to get the final and correct answer. We don't check
		// for the error and just continue (even if it means the user has still
		// the wrong instance type) to have a seamles experience on the client
		// side, rather than aborting it.
		retry(3*time.Minute, func() error {
			instance, err := m.Session.AWSClient.Instance()
			if err != nil {
				return err
			}

			if instance.InstanceType != m.Meta.InstanceType {
				return fmt.Errorf("Instance is still '%s', waiting until it changed to '%s'",
					instance.InstanceType, m.Meta.InstanceType)
			}

			return nil
		})
	}

	infoState := amazon.StatusToState(instance.State.Name)

	// only start if the machine is stopped, stopping
	if infoState.In(machinestate.Stopped, machinestate.Stopping) {
		// Give time until it's being stopped
		if infoState == machinestate.Stopping {
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

	// now we can assume that the machine is running
	latestState = machinestate.Running

	// Assign a Elastic IP for a paying customer if it doesn't have any
	// assigned yet (Elastic IP's are assigned only during the Build). We
	// lookup the IP from the Elastic IPs, if it's not available (returns an
	// error) we proceed and create it.
	if m.Payment.Plan != "free" { // check this first to avoid an additional AWS call
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
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err.Error())
	}

	// also get all domain aliases that belongs to this machine and unset
	m.push("Updating domain aliases", 80, machinestate.Starting)
	domains, err := m.Session.DNSStorage.GetByMachine(m.Id.Hex())
	if err != nil {
		m.Log.Error("fetching domains for starting err: %s", err.Error())
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err.Error())
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
