package koding

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/plans"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/fatih/structs"
	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

func (m *Machine) Start(ctx context.Context) (err error) {
	if err := m.UpdateState("Machine is starting", machinestate.Starting); err != nil {
		return err
	}

	instance, err := m.Session.AWSClient.Instance()
	if (err == nil && amazon.StatusToState(aws.StringValue(instance.State.Name)) == machinestate.Terminated) ||
		amazon.IsNotFound(err) {
		// This means the instanceId stored in MongoDB doesn't exist anymore in
		// AWS. Probably it was deleted and the state was not updated (possible
		// due a human interaction or a non kloud interaction done somewhere
		// else.)
		if err := m.markAsNotInitialized(); err != nil {
			return err
		}

		return errors.New("instance is not available anymore.")
	}
	if err != nil {
		return fmt.Errorf("failed to get instance %q: %q", m.Session.AWSClient.Builder.InstanceId, err)
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

	meta, err := m.GetMeta()
	if err != nil {
		return err
	}

	// if it's something else (the error from Instance() call above) return it
	// back
	if err != nil {
		return err
	}

	if err := m.Checker.AlwaysOn(m.Username); err != nil {
		return err
	}

	if err := m.Checker.NetworkUsage(m.Username); err != nil {
		return err
	}

	if strings.ToLower(m.Payment.State) == "expired" {
		return fmt.Errorf("[%s] Plan is expired", m.ObjectId.Hex())
	}

	m.push("Starting machine", 10, machinestate.Starting)

	// check if the user has something else than their current instance type
	// and revert back to t2.nano. This is lazy auto healing of instances that
	// were created because there were no capacity for their specific instance
	// type.
	if typ := aws.StringValue(instance.InstanceType); typ != "" && meta.InstanceType != "" && typ != meta.InstanceType {
		m.Log.Warning("instance is using %q. Changing back to %q", typ, meta.InstanceType)

		params := &ec2.ModifyInstanceAttributeInput{
			InstanceId: aws.String(meta.InstanceId),
			InstanceType: &ec2.AttributeValue{
				Value: aws.String(plans.Instances[meta.InstanceType].String()),
			},
		}

		if err := m.Session.AWSClient.ModifyInstance(params); err != nil {
			m.Log.Warning("couldn't change instance to '%s' again. err: %s",
				meta.InstanceType, err)
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

			if aws.StringValue(instance.InstanceType) != meta.InstanceType {
				return fmt.Errorf("Instance is still %q, waiting until it changed to %q",
					aws.StringValue(instance.InstanceType), meta.InstanceType)
			}

			m.Log.Debug("Instance type successfully changed to %s", meta.InstanceType)
			return nil
		})
	}

	infoState := amazon.StatusToState(aws.StringValue(instance.State.Name))

	// only start if the machine is stopped, stopping
	if infoState.In(machinestate.Stopped, machinestate.Stopping) {
		// Give time until it's being stopped
		if infoState == machinestate.Stopping {
			time.Sleep(time.Second * 20)
		}

		// Assign a Elastic IP for a paying customer if it doesn't have any
		// assigned yet (Elastic IP's are assigned only during the Build). We
		// lookup the IP from the Elastic IPs, if it's not available (returns an
		// error) we proceed and create it.
		if plan, ok := plans.Plans[m.Payment.Plan]; ok && plan != plans.Free {
			m.Log.Debug("Checking if IP is an Elastic IP for paying user: (ip: %s)", m.IpAddress)

			_, err = m.Session.AWSClient.AddressesByIP(m.IpAddress)
			if amazon.IsNotFound(err) {
				oldIp := m.IpAddress
				elasticIp, err := m.Session.AWSClient.AllocateAndAssociateIP(meta.InstanceId)

				m.Log.Info(
					"Paying user without Elastic IP detected. Assigning IP. (username: %s, instanceId: %s, region: %s, oldIp: %s, newIp: %s)",
					m.Credential, meta.InstanceId, meta.Region, oldIp, elasticIp,
				)

				if err != nil {
					m.Log.Error("couldn't not create elastic IP: %s", err)
				} else {
					m.IpAddress = elasticIp
				}
			} else if err != nil {
				m.Log.Error(
					"Failed to retrieve Elastic IP information: %s (username: %s, instanceId: %s, region: %s, ip: %s)",
					err, m.Credential, meta.InstanceId, meta.Region, m.IpAddress,
				)
			}
		}

		startFunc := func() error {
			instance, err := m.Session.AWSClient.Start(ctx)
			if err == nil {
				m.IpAddress = aws.StringValue(instance.PublicIpAddress)
				meta.InstanceType = aws.StringValue(instance.InstanceType)
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
					instanceType, meta.InstanceType)

				// now change the instance type before we start so we can
				// avoid the instance capacity problem
				params := &ec2.ModifyInstanceAttributeInput{
					InstanceId: aws.String(meta.InstanceId),
					InstanceType: &ec2.AttributeValue{
						Value: aws.String(instanceType),
					},
				}
				if err := m.Session.AWSClient.ModifyInstance(params); err != nil {
					return err
				}

				// just give a little time so it can be catched because EC2 is
				// eventuall consistent. Otherwise start might fail even if we
				// do the ModifyInstance call
				time.Sleep(time.Second * 2)

				instance, err = m.Session.AWSClient.Start(ctx)
				if err == nil {
					m.IpAddress = aws.StringValue(instance.PublicIpAddress)
					meta.InstanceType = aws.StringValue(instance.InstanceType)
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

	m.push("Initializing domain instance", 65, machinestate.Starting)
	if err := m.Session.DNSClient.Validate(m.Domain, m.Username); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	if err := m.Session.DNSClient.Upsert(m.Domain, m.IpAddress); err != nil {
		m.Log.Error("couldn't update machine domain: %s", err)
	}

	// also get all domain aliases that belongs to this machine and unset
	m.push("Updating domain aliases", 80, machinestate.Starting)
	domains, err := m.Session.DNSStorage.GetByMachine(m.ObjectId.Hex())
	if err != nil {
		m.Log.Error("fetching domains for starting err: %s", err)
	}

	for _, domain := range domains {
		if err := m.Session.DNSClient.Validate(domain.Name, m.Username); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
		if err := m.Session.DNSClient.Upsert(domain.Name, m.IpAddress); err != nil {
			m.Log.Error("couldn't update machine domain: %s", err)
		}
	}

	m.push("Checking remote machine", 90, machinestate.Starting)
	if !m.isKlientReady() {
		return errors.New("klient is not ready")
	}

	m.Meta = structs.Map(meta) // update meta

	return m.Session.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.UpdateId(
			m.ObjectId,
			bson.M{"$set": bson.M{
				"ipAddress":          m.IpAddress,
				"meta.instanceName":  meta.InstanceName,
				"meta.instanceId":    meta.InstanceId,
				"meta.instance_type": meta.InstanceType,
				"status.state":       machinestate.Running.String(),
				"status.modifiedAt":  time.Now().UTC(),
				"status.reason":      "Machine is running",
			}},
		)
	})
}
