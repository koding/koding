package test

type StepAction uint

const (
	Continue StepAction = iota
	Halt
)

const (
	StateCancelled = "cancelled"
	StateHalted    = "halted"
)

type Step interface {
	Run(AzureStateBag) StepAction

	Cleanup(AzureStateBag)
}
