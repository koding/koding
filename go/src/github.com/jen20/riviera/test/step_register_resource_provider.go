package test

import (
	"log"

	"github.com/jen20/riviera/azure"
)

type StepRegisterResourceProvider struct {
	Namespace string
}

func (s *StepRegisterResourceProvider) Run(state AzureStateBag) StepAction {
	azureClient := state.Client()

	log.Printf("[INFO] Registering resource provider %q...", s.Namespace)

	r := azureClient.NewRequest()

	r.Command = azure.RegisterResourceProvider{
		Namespace: s.Namespace,
	}

	response, err := r.Execute()
	if err != nil {
		state.AppendError(err)
		return Halt
	}

	if response.IsSuccessful() {
		return Continue
	}

	state.AppendError(response.Error)
	return Halt
}

func (s *StepRegisterResourceProvider) Cleanup(state AzureStateBag) {
	//TODO(jen20): Decide if we should unregister these.
}
