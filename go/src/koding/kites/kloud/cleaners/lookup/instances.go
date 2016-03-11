package lookup

import (
	"errors"
	"fmt"
	"strings"
	"time"

	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/hashicorp/go-multierror"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Instances represents a list of ec2.Instances
type Instances map[string]*ec2.Instance

// OlderThan filters out instances that are older than the given duration.
func (i Instances) OlderThan(duration time.Duration) Instances {
	filtered := make(Instances, 0)

	for id, instance := range i {
		oldDate := time.Now().UTC().Add(-duration)

		if instance.LaunchTime.Before(oldDate) {
			filtered[id] = instance
		}
	}

	return filtered
}

// States filters out instances which that particular state
func (i Instances) States(states ...string) Instances {
	filtered := make(Instances)

	// possible state names:
	//  (pending | running | shutting-down | terminated | stopping | stopped).
	for id, instance := range i {
		if has(aws.StringValue(instance.State.Name), states...) {
			filtered[id] = instance
		}
	}

	return filtered
}

// Has returns true if the given ids exists.
func (i Instances) Has(id string) bool {
	_, ok := i[id]
	return ok
}

// Delete deletes the instance with the given Id from the instances list
func (i Instances) Delete(id string) {
	delete(i, id)
}

// WithTag filters out instances which contains that particular tag's key and
// corresponding values
func (i Instances) WithTag(key string, values ...string) Instances {
	filtered := make(Instances, 0)

	for id, instance := range i {
		for _, tag := range instance.Tags {
			if aws.StringValue(tag.Key) == key && has(aws.StringValue(tag.Value), values...) {
				filtered[id] = instance
			}
		}
	}

	return filtered
}

// Ids returns the list of ids of the instances,
func (i Instances) Ids() []string {
	ids := make([]string, 0)

	for id := range i {
		ids = append(ids, id)
	}

	return ids
}

func deleteDocument(i *ec2.Instance, db *mongodb.MongoDB) error {
	if i == nil {
		return errors.New("nil instance")
	}

	var id bson.ObjectId

	for _, tag := range i.Tags {
		key := strings.ToLower(aws.StringValue(tag.Key))
		value := strings.ToLower(aws.StringValue(tag.Value))

		if key != "koding-machineid" || value == "" {
			continue
		}

		id = bson.ObjectIdHex(value)
		break
	}

	if !id.Valid() {
		return errors.New("unable to find valid jMachine.ObjectId")
	}

	return db.Run(modelhelper.MachinesColl, func(c *mgo.Collection) error { return c.RemoveId(id) })
}

// Terminate terminates all instances
func (i Instances) TerminateAll(client *amazon.Client) {
	if len(i) == 0 {
		return
	}

	for _, split := range splittedIds(i.Ids(), 500) {
		_, err := client.TerminateInstances(split...)
		if err != nil {
			fmt.Printf("[%s] terminate error: %s\n", client.Region, err)
			continue
		}
	}
}

func (i Instances) DeleteDocs(db *mongodb.MongoDB) {
	merr := new(multierror.Error)

	for id, instance := range i {
		if err := deleteDocument(instance, db); err != nil {
			merr = multierror.Append(merr, fmt.Errorf("instance %q error: %s", id, err))
		}
	}

	if err := merr.ErrorOrNil(); err != nil {
		fmt.Printf("deleting documents error: %s\n", err)
	}
}

// Terminate terminates the given instance specified with the id
func (i Instances) Terminate(client *amazon.Client, db *mongodb.MongoDB, id string) {
	if id == "" {
		return
	}

	_, err := client.TerminateInstance(id)
	if err != nil {
		fmt.Printf("[%s] terminate error: %s\n", client.Region, err)
	} else {
		if err := deleteDocument(i[id], db); err != nil {
			fmt.Printf("[%s] deleting document for %q error: %s\n", client.Region, id, err)
		}
	}
}

// Stop stop all instances
func (i Instances) StopAll(client *amazon.Client) {
	if len(i) == 0 {
		return
	}

	for _, split := range splittedIds(i.Ids(), 500) {
		_, err := client.StopInstances(split...)
		if err != nil {
			fmt.Printf("[%s] stop error: %s\n", client.Region, err)
		}
	}
}

// splittedIds splits the ids into a list of ids each with the given split
// capacity
func splittedIds(ids []string, split int) [][]string {
	if split == 0 {
		panic("split number must be greater than 0")
	}

	// we split the ids because AWS doesn't allow us to terminate more than 500
	// instances, so for example if we have 1890 instances, we'll going to make
	// four API calls with ids of 500, 500, 500 and 390
	var splitted [][]string
	for len(ids) >= split {
		splitted = append(splitted, ids[:split])
		ids = ids[split:]
	}
	splitted = append(splitted, ids) // remaining
	return splitted
}

// has checks wether the given value existing inside the values
func has(value string, values ...string) bool {
	for _, v := range values {
		if v == value {
			return true
		}
	}
	return false
}
