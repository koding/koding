package test

import (
	"fmt"
	"log"

	"reflect"

	"github.com/jen20/riviera/azure"
)

type StepRunCommand struct {
	RunCommand         azure.APICall
	CleanupCommand     azure.APICall
	StateCommandURIKey string
	StateCommand       azure.APICall
	StateBagKey        string
}

func (s *StepRunCommand) Run(state AzureStateBag) StepAction {
	if s.RunCommand == nil && s.StateCommand == nil {
		return Continue
	}

	azureClient := state.Client()
	if s.RunCommand != nil {
		log.Printf("[INFO] Running %T command...", s.RunCommand)

		r := azureClient.NewRequest()
		r.Command = s.RunCommand
		response, err := r.Execute()
		if err != nil {
			state.AppendError(err)
			return Halt
		}

		if response.IsSuccessful() {
			state.Put(s.StateBagKey, response.Parsed)
		} else {
			state.AppendError(response.Error)
			return Halt
		}
	}

	if s.StateCommand != nil {
		log.Printf("[INFO] Refreshing state with %T command...", s.StateCommand)

		var r *azure.Request
		if s.StateCommandURIKey == "" {
			r = azureClient.NewRequest()
		} else {
			uri, err := uriFromStateBagKey(state, s.StateBagKey, s.StateCommandURIKey)
			if err != nil {
				state.AppendError(err)
				return Halt
			}
			if uri == "" {
				state.AppendError(fmt.Errorf("URI from state bag was empty - check the (case-sensitive) paths in the test"))
				return Halt
			}
			r = azureClient.NewRequestForURI(uri)
		}

		r.Command = s.StateCommand
		response, err := r.Execute()
		if err != nil {
			state.AppendError(err)
			return Halt
		}

		if response.IsSuccessful() {
			state.Remove(s.StateBagKey)
			state.Put(s.StateBagKey, response.Parsed)
			return Continue
		}

		state.Remove(s.StateBagKey)
		state.AppendError(response.Error)
		return Halt
	}

	return Continue
}

func (s *StepRunCommand) Cleanup(state AzureStateBag) {
	if s.CleanupCommand == nil {
		return
	}
	azureClient := state.Client()

	log.Printf("[INFO] Cleaning up with %T command...", s.CleanupCommand)

	request := azureClient.NewRequest()
	request.Command = s.CleanupCommand
	response, err := request.Execute()
	if err != nil {
		state.AppendError(err)
		return
	}

	if !response.IsSuccessful() {
		log.Printf("[INFO] Error running clean up %T command", s.CleanupCommand)
		state.AppendError(response.Error)
	}
}

func uriFromStateBagKey(state AzureStateBag, stateBagKey, propertyPath string) (string, error) {
	item, ok := state.GetOk(stateBagKey)
	if !ok {
		return "", fmt.Errorf("State bag key %q not found in state", stateBagKey)
	}

	itemValue := reflect.ValueOf(item)

	switch itemValue.Kind() {
	case reflect.Struct:
		uriField := itemValue.FieldByName(propertyPath)

		//TODO(jen20): zero handling

		return uriField.String(), nil
	case reflect.Ptr:
		actualValue := itemValue.Elem()
		if actualValue.Kind() != reflect.Struct {
			return "", fmt.Errorf("State bag key %q is not a struct or pointer to struct", stateBagKey)
		}
		uriField := actualValue.FieldByName(propertyPath)

		//TODO(jen20): zero handling

		return uriField.String(), nil

	default:
		return "", fmt.Errorf("State bag key %q is not a struct or pointer to struct", stateBagKey)
	}
}
