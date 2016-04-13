package test

import (
	"fmt"
	"log"

	"github.com/abdullin/seq"
)

type AssertFunc func(AzureStateBag) error

type StepAssert struct {
	StateBagKey string
	Assertions  seq.Map
}

func (s *StepAssert) Run(state AzureStateBag) StepAction {
	actual, ok := state.GetOk(s.StateBagKey)
	if !ok {
		state.AppendError(fmt.Errorf("Key %q not found in state", s.StateBagKey))
	}

	for k, v := range s.Assertions {
		path := fmt.Sprintf("%s.%s", s.StateBagKey, k)
		log.Printf("[INFO] Asserting %q has value \"%v\"...", path, v)
	}

	result := s.Assertions.Test(actual)

	if result.Ok() {
		return Continue
	}

	for _, v := range result.Issues {
		err := fmt.Sprintf("Expected %q to be \"%v\" but got %q",
			v.Path,
			v.ExpectedValue,
			v.ActualValue,
		)
		state.AppendError(fmt.Errorf(err))
	}

	return Halt
}

func (s *StepAssert) Cleanup(state AzureStateBag) {
}
