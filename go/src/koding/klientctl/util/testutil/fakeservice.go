package testutil

// FakeService implements a Service.
type FakeService struct {
	StartCount int
	StopCount  int
	StartError error
	StopError  error
	// Defaults to klient running
	KlientIsntRunning bool
}

func (s *FakeService) IsKlientRunning() bool {
	return !s.KlientIsntRunning
}

func (s *FakeService) Start() error {
	s.StartCount++
	return s.StartError
}

func (s *FakeService) Stop() error {
	s.StopCount++
	return s.StopError
}
