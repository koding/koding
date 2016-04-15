package cloudapi_test

import (
	gc "launchpad.net/gocheck"

	"github.com/joyent/gosdc/cloudapi"
	"time"
)

func (s *LocalTests) TestCreateMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	c.Assert(testMachine.Type, gc.Equals, "smartmachine")
	c.Assert(testMachine.Memory, gc.Equals, 1024)
	c.Assert(testMachine.Disk, gc.Equals, 16384)
	c.Assert(testMachine.Package, gc.Equals, localPackageName)
	c.Assert(testMachine.Image, gc.Equals, localImageID)
}

func (s *LocalTests) TestListMachines(c *gc.C) {
	s.listMachines(c, nil)
}

func (s *LocalTests) TestListMachinesWithFilter(c *gc.C) {
	filter := cloudapi.NewFilter()
	filter.Set("memory", "1024")

	s.listMachines(c, filter)
}

/*func (s *LocalTests) TestCountMachines(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	count, err := s.testClient.CountMachines()
	c.Assert(err, gc.IsNil)
	c.Assert(count >= 1, gc.Equals, true)
}*/

func (s *LocalTests) TestGetMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	machine, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(machine, gc.NotNil)
	c.Assert(machine.Equals(*testMachine), gc.Equals, true)
}

func (s *LocalTests) TestStopMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.StopMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LocalTests) TestStartMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.StopMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)

	// wait for machine to be stopped
	for !s.pollMachineState(c, testMachine.Id, "stopped") {
		time.Sleep(1 * time.Second)
	}

	err = s.testClient.StartMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LocalTests) TestRebootMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.RebootMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
}

func (s *LocalTests) TestRenameMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.RenameMachine(testMachine.Id, "test-machine-renamed")
	c.Assert(err, gc.IsNil)

	renamed, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(renamed.Name, gc.Equals, "test-machine-renamed")
}

func (s *LocalTests) TestResizeMachine(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	err := s.testClient.ResizeMachine(testMachine.Id, "Medium")
	c.Assert(err, gc.IsNil)

	resized, err := s.testClient.GetMachine(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(resized.Package, gc.Equals, "Medium")
}

func (s *LocalTests) TestDeleteMachine(c *gc.C) {
	testMachine := s.createMachine(c)

	s.deleteMachine(c, testMachine.Id)
}
