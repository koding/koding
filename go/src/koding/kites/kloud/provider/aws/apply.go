package awsprovider

import (
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/stackstate"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"
)

// Apply
func (s *Stack) Apply(ctx context.Context) (interface{}, error) {
	var arg kloud.ApplyRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	stack, err := modelhelper.GetComputeStack(arg.StackID)
	if err != nil {
		return nil, err
	}

	if stack.State().InProgress() {
		return nil, fmt.Errorf("State is currently %s. Please try again later", stack.State())
	}

	if arg.Destroy {
		s.Eventer.Push(&eventer.Event{
			Message: s.Req.Method + " started",
			Status:  machinestate.Terminating,
		})
	} else {
		s.Eventer.Push(&eventer.Event{
			Message: s.Req.Method + " started",
			Status:  machinestate.Building,
		})
	}

	go func() {
		finalEvent := &eventer.Event{
			Message:    s.Req.Method + " finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		start := time.Now()

		var err error
		if arg.Destroy {
			modelhelper.SetStackState(arg.StackID, "Stack destroying started",
				stackstate.Destroying)

			s.Log.New(arg.StackID).Info("======> %s (destroy) started <======",
				strings.ToUpper(s.Req.Method))
			finalEvent.Status = machinestate.Terminated
			err = destroy(ctx, s.Req.Username, arg.GroupName, arg.StackID)
		} else {
			modelhelper.SetStackState(arg.StackID, "Stack building started", stackstate.Building)

			s.Log.New(arg.StackID).Info("======> %s started <======", strings.ToUpper(s.Req.Method))
			err = apply(ctx, s.Req.Username, arg.GroupName, arg.StackID)
			if err != nil {
				modelhelper.SetStackState(arg.StackID, "Stack building failed",
					stackstate.NotInitialized)
				finalEvent.Status = machinestate.NotInitialized
			} else {
				modelhelper.SetStackState(arg.StackID, "Stack building finished",
					stackstate.Initialized)
			}

		}

		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			s.Log.New(arg.StackID).Error("%s error: %s", s.Req.Method, err)

			finalEvent.Error = err.Error()
			s.Log.New(arg.StackID).Error("======> %s finished with error (time: %s): '%s' <======",
				strings.ToUpper(s.Req.Method), time.Since(start), err.Error())
		} else {
			s.Log.New(arg.StackID).Info("======> %s finished (time: %s) <======",
				strings.ToUpper(s.Req.Method), time.Since(start))
		}

		s.Eventer.Push(finalEvent)
	}()

	return kloud.ControlResult{
		EventId: s.Eventer.ID(),
	}, nil
}

func destroy(ctx context.Context, username, groupname, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("request context is not passed")
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	stack, err := fetchStack(stackId)
	if err != nil {
		return err
	}

	sess.Log.Debug("Validating '%d' machines from user '%s'", len(stack.Machines), username)
	machines, err := fetchMachines(ctx, stack.Machines...)
	if err != nil {
		return err
	}
	sess.Log.Debug("Fetched machines: %+v", machines)

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.Credentials), username)
	data, err := stackplan.FetchTerraformData(req.Method, username, groupname, stackplan.FlattenValues(stack.Credentials))
	if err != nil {
		return err
	}
	sess.Log.Debug("Fetched terraform data: %+v", data)

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	sess.Log.Debug("Parsing the template")
	template, err := stackplan.ParseTemplate(stack.Template)
	if err != nil {
		return err
	}

	sess.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")
	for _, cred := range data.Creds {
		if err := template.InjectCustomVariables(cred.Provider, cred.Data); err != nil {
			return err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		region, ok := cred.Data["region"]
		if !ok {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := template.SetAwsRegion(region); err != nil {
			return err
		}
	}

	// inject koding variables, in the form of koding_user_foo,
	// koding_group_name, etc..
	if err := template.InjectKodingVariables(data.KodingData); err != nil {
		return err
	}

	if _, err := stackplan.InjectAWSData(ctx, template, username, data); err != nil {
		return err
	}

	if _, err := stackplan.InjectVagrantData(ctx, template, username); err != nil {
		return err
	}

	out, err := template.JsonOutput()
	if err != nil {
		return err
	}

	stack.Template = out

	tfReq := &tf.TerraformRequest{
		Content:   stack.Template,
		ContentID: username + "-" + stackId,
		Variables: nil,
	}
	sess.Log.Debug("Calling terraform.destroy method with context:")
	sess.Log.Debug("%+v", tfReq)

	_, err = tfKite.Destroy(tfReq)
	if err != nil {
		return err
	}

	for _, m := range machines {
		if err := modelhelper.DeleteMachine(m.ObjectId); err != nil {
			return err
		}
	}

	return modelhelper.DeleteComputeStack(stackId)
}

func apply(ctx context.Context, username, groupname, stackId string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	ev, ok := eventer.FromContext(ctx)
	if !ok {
		return errors.New("eventer context is not passed")
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return errors.New("internal server error (err: session context is not available)")
	}

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating machines",
		Percentage: 20,
		Status:     machinestate.Building,
	})

	stack, err := fetchStack(stackId)
	if err != nil {
		return err
	}
	sess.Log.Debug("Fetched stack: %+v", stack)

	sess.Log.Debug("Fetching and validating '%d' machines from user '%s'", len(stack.Machines), username)
	machines, err := fetchMachines(ctx, stack.Machines...)
	if err != nil {
		return err
	}
	sess.Log.Debug("Fetched machines: %+v", machines)

	ev.Push(&eventer.Event{
		Message:    "Fetching and validating credentials",
		Percentage: 30,
		Status:     machinestate.Building,
	})

	sess.Log.Debug("Fetching '%d' credentials from user '%s'", len(stack.Credentials), username)
	data, err := stackplan.FetchTerraformData(req.Method, username, groupname, stackplan.FlattenValues(stack.Credentials))
	if err != nil {
		return err
	}
	sess.Log.Debug("Fetched terraform data: %+v", data)

	sess.Log.Debug("Connection to Terraformer")
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return err
	}
	defer tfKite.Close()

	sess.Log.Debug("Parsing the template")
	sess.Log.Debug("%s", stack.Template)
	template, err := stackplan.ParseTemplate(stack.Template)
	if err != nil {
		return err
	}

	sess.Log.Debug("Stack template before injecting Koding data:")
	sess.Log.Debug("%s", template)

	sess.Log.Debug("Injecting variables from credential data identifiers, such as aws, custom, etc..")

	var region string
	for _, cred := range data.Creds {
		sess.Log.Debug("Appending %s provider variables", cred.Provider)
		if err := template.InjectCustomVariables(cred.Provider, cred.Data); err != nil {
			return err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		credRegion, ok := cred.Data["region"]
		if !ok {
			return fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		// check if this a second round and it's using a different region, we
		// shouldn't allow it.
		if region != "" && region != credRegion {
			return fmt.Errorf("multiple credentials with multiple regions detected: %s and %s. Aborting",
				region, credRegion)
		}

		region = credRegion

		if err := template.SetAwsRegion(region); err != nil {
			return err
		}
	}

	sess.Log.Debug("Injecting Koding data")
	// inject koding variables, in the form of koding_user_foo,
	// koding_group_name, etc..
	if err := template.InjectKodingVariables(data.KodingData); err != nil {
		return err
	}

	kiteIds := make(map[string]string)

	awsData, err := stackplan.InjectAWSData(ctx, template, username, data)
	if err != nil {
		return err
	}

	if awsData != nil && awsData.KiteIds != nil {
		for label, id := range awsData.KiteIds {
			kiteIds[label] = id
		}
	}

	vagrantData, err := stackplan.InjectVagrantData(ctx, template, username)
	if err != nil {
		return err
	}

	if vagrantData != nil && vagrantData.KiteIds != nil {
		for label, id := range vagrantData.KiteIds {
			kiteIds[label] = id
		}
	}

	out, err := template.JsonOutput()
	if err != nil {
		return err
	}
	stack.Template = out

	done := make(chan struct{})

	// because apply can last long, we are going to increment the eventer's
	// percentage as long as we build automatically.
	go func() {
		ticker := time.NewTicker(time.Second * 5)
		start := 45

		for {
			select {
			case <-done:
				return
			case <-ticker.C:
				if start < 70 {
					start += 5
				}

				ev.Push(&eventer.Event{
					Message:    "Building stack resources",
					Percentage: start,
					Status:     machinestate.Building,
				})
			}
		}
	}()

	tfReq := &tf.TerraformRequest{
		Content:   stack.Template,
		ContentID: username + "-" + stackId,
		Variables: nil,
	}
	sess.Log.Debug("Final stack template. Calling terraform.apply method:")
	sess.Log.Debug("%+v", tfReq)

	state, err := tfKite.Apply(tfReq)
	if err != nil {
		close(done)
		return err
	}

	fmt.Printf("state = %+v\n", state)

	close(done)

	ev.Push(&eventer.Event{
		Message:    "Checking VM connections",
		Percentage: 70,
		Status:     machinestate.Building,
	})

	if len(kiteIds) != 0 {
		sess.Log.Debug("Checking total '%d' klients", len(kiteIds))
		if err := stackplan.CheckKlients(ctx, kiteIds); err != nil {
			return err
		}
	}

	output, err := stackplan.MachinesFromState(state)
	if err != nil {
		return err
	}

	sess.Log.Debug("Machines from state: %+v", output)
	sess.Log.Debug("Build region: %+v", region)
	output.AppendRegion(region)

	if len(kiteIds) != 0 {
		sess.Log.Debug("Build data kiteIDS: %+v", kiteIds)
		output.AppendQueryString(kiteIds)
	}

	d, err := json.MarshalIndent(output, "", " ")
	if err != nil {
		return err
	}
	sess.Log.Debug("Updated machines\n%s", string(d))

	sess.Log.Debug("Updating and syncing terraform output to jMachine documents")
	ev.Push(&eventer.Event{
		Message:    "Updating machine settings",
		Percentage: 90,
		Status:     machinestate.Building,
	})
	return updateMachines(ctx, output, machines)
}

func fetchStack(stackId string) (*stackplan.Stack, error) {
	computeStack, err := modelhelper.GetComputeStack(stackId)
	if err != nil {
		return nil, err
	}

	stackTemplate, err := modelhelper.GetStackTemplate(computeStack.BaseStackId.Hex())
	if err != nil {
		return nil, err
	}

	machineIds := make([]string, len(computeStack.Machines))
	for i, m := range computeStack.Machines {
		machineIds[i] = m.Hex()
	}

	credentials := make(map[string][]string, 0)

	// first copy admin/group based credentials
	for k, v := range stackTemplate.Credentials {
		credentials[k] = v
	}

	// copy user based credentials
	for k, v := range computeStack.Credentials {
		// however don't override anything the admin already added
		if _, ok := credentials[k]; !ok {
			credentials[k] = v
		}
	}

	return &stackplan.Stack{
		Machines:    machineIds,
		Credentials: credentials,
		Template:    stackTemplate.Template.Content,
	}, nil
}

func fetchMachines(ctx context.Context, ids ...string) ([]*models.Machine, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	mongodbIds := make([]bson.ObjectId, len(ids))
	for i, id := range ids {
		mongodbIds[i] = bson.ObjectIdHex(id)
	}

	sess.Log.Debug("Fetching machines with IDs: %+v", mongodbIds)

	machines := make([]*models.Machine, 0)
	if err := sess.DB.Run("jMachines", func(c *mgo.Collection) error {
		return c.Find(bson.M{"_id": bson.M{"$in": mongodbIds}}).All(&machines)
	}); err != nil {
		return nil, err
	}

	validUsers := make(map[string]models.MachineUser, 0)
	validMachines := make(map[string]*models.Machine, 0)

	for _, machine := range machines {
		// machines with empty users are supposed to allowed by default
		// (gokmen)
		if machine.Users == nil || len(machine.Users) == 0 {
			validMachines[machine.ObjectId.Hex()] = machine
			continue
		}

		// for others we need to be sure they are valid
		// TODO(arslan): add custom type with custom methods for type
		// []*Machineuser
		for _, user := range machine.Users {
			// we only going to select users that are allowed
			if user.Sudo && user.Owner {
				validUsers[user.Id.Hex()] = user
			} else {
				// return early, we don't tolerate nonvalid inputs to apply
				return nil, fmt.Errorf("machine '%s' is not valid. Aborting apply",
					machine.ObjectId.Hex())
			}
		}
	}

	allowedIds := make([]bson.ObjectId, 0)
	for _, user := range validUsers {
		allowedIds = append(allowedIds, user.Id)
	}

	sess.Log.Debug("Fetching users with allowed IDs: %+v", allowedIds)
	users, err := modelhelper.GetUsersById(allowedIds...)
	if err != nil {
		return nil, err
	}

	req, ok := request.FromContext(ctx)
	if !ok {
		return nil, errors.New("request context is not passed")
	}

	// find whether requested user is among allowed ones
	var reqUser *models.User
	for _, u := range users {
		if u.Name == req.Username {
			reqUser = u
			break
		}
	}

	if reqUser != nil {
		// now check if the requested user is inside the allowed users list
		for _, m := range machines {
			for _, user := range m.Users {
				if user.Id.Hex() == reqUser.ObjectId.Hex() {
					validMachines[m.ObjectId.Hex()] = m
					break
				}
			}
		}
	}

	if len(validMachines) == 0 {
		return nil, fmt.Errorf("no valid machines found for the user: %s", req.Username)
	}

	finalMachines := make([]*models.Machine, 0)
	for _, m := range validMachines {
		finalMachines = append(finalMachines, m)
	}

	return finalMachines, nil
}

func updateMachines(ctx context.Context, data *stackplan.Machines, jMachines []*models.Machine) error {
	for _, machine := range jMachines {
		label := machine.Label
		if l, ok := machine.Meta["assignedLabel"]; ok {
			if ll, ok := l.(string); ok {
				label = ll
			}
		}

		tf, err := data.WithLabel(label)
		if err != nil {
			return fmt.Errorf("machine label '%s' doesn't exist in terraform output", label)
		}

		switch tf.Provider {
		case "aws":
			if err := updateAWS(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		case "vagrantkite":
			if err := updateVagrantKite(ctx, tf, machine.ObjectId); err != nil {
				return err
			}
		}
	}

	return nil
}

func updateAWS(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
	size, err := strconv.Atoi(tf.Attributes["root_block_device.0.volume_size"])
	if err != nil {
		return err
	}

	return modelhelper.UpdateMachine(machineId, bson.M{"$set": bson.M{
		"provider":           tf.Provider,
		"meta.region":        tf.Region,
		"queryString":        tf.QueryString,
		"ipAddress":          tf.Attributes["public_ip"],
		"meta.instanceId":    tf.Attributes["id"],
		"meta.instance_type": tf.Attributes["instance_type"],
		"meta.source_ami":    tf.Attributes["ami"],
		"meta.storage_size":  size,
		"status.state":       machinestate.Running.String(),
		"status.modifiedAt":  time.Now().UTC(),
		"status.reason":      "Created with kloud.apply",
	}})
}

func updateVagrantKite(ctx context.Context, tf stackplan.Machine, machineId bson.ObjectId) error {
	return modelhelper.UpdateMachine(machineId, bson.M{"$set": bson.M{
		"provider":            tf.Provider,
		"queryString":         tf.QueryString,
		"ipAddress":           tf.Attributes["ipAddress"],
		"meta.filePath":       tf.Attributes["filePath"],
		"meta.memory":         tf.Attributes["memory"],
		"meta.cpus":           tf.Attributes["cpus"],
		"meta.box":            tf.Attributes["box"],
		"meta.hostname":       tf.Attributes["hostname"],
		"meta.klientHostURL":  tf.Attributes["klientHostURL"],
		"meta.klientGuestURL": tf.Attributes["klientGuestURL"],
		"status.state":        machinestate.Running.String(),
		"status.modifiedAt":   time.Now().UTC(),
		"status.reason":       "Created with kloud.apply",
	}})
}
