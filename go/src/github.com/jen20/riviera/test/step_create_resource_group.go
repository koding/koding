package test

import (
	"log"

	"github.com/jen20/riviera/azure"
)

type StepCreateResourceGroup struct {
	Name     string
	Location string
	Tags     map[string]*string
}

func (s *StepCreateResourceGroup) Run(state AzureStateBag) StepAction {
	azureClient := state.Client()

	log.Printf("[INFO] Creating resource group %q (%s)...", s.Name, s.Location)

	r := azureClient.NewRequest()

	r.Command = azure.CreateResourceGroup{
		Name:     s.Name,
		Location: s.Location,
		Tags:     s.Tags,
	}

	response, err := r.Execute()
	if err != nil {
		state.AppendError(err)
		return Halt
	}

	if response.IsSuccessful() {
		state.Put("resourcegroup", *response.Parsed.(*azure.CreateResourceGroupResponse))
		return Continue
	}

	state.AppendError(response.Error)
	return Halt
}

func (s *StepCreateResourceGroup) Cleanup(state AzureStateBag) {
	azureClient := state.Client()

	log.Printf("[INFO] Cleaning up resource group %q...", s.Name)

	request := azureClient.NewRequest()
	request.Command = azure.DeleteResourceGroup{
		Name: s.Name,
	}

	response, err := request.Execute()
	if err != nil {
		state.AppendError(err)
		return
	}

	if !response.IsSuccessful() {
		log.Printf("[INFO] Error deleting resource group %q", s.Name)
		state.AppendError(response.Error)
	}
}
