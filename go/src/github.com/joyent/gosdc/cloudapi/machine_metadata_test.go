package cloudapi_test

import gc "launchpad.net/gocheck"

func (s *LocalTests) TestUpdateMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	metadata := map[string]string{"test": "a"}
	newMetadata, err := s.testClient.UpdateMachineMetadata(testMachine.Id, metadata)

	c.Assert(err, gc.IsNil)
	c.Assert(metadata["test"], gc.Equals, newMetadata["test"])
}

func (s *LocalTests) TestGetMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	metadata := map[string]string{"test": "a"}
	_, err := s.testClient.UpdateMachineMetadata(testMachine.Id, metadata)
	c.Assert(err, gc.IsNil)

	newMetadata, err := s.testClient.GetMachineMetadata(testMachine.Id)

	c.Assert(err, gc.IsNil)
	c.Assert(metadata["test"], gc.Equals, newMetadata["test"])
}

func (s *LocalTests) TestDeleteMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.UpdateMachineMetadata(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	err = s.testClient.DeleteMachineMetadata(testMachine.Id, "test")
	c.Assert(err, gc.IsNil)
}

func (s *LocalTests) TestDeleteAllMachineMetadata(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.UpdateMachineMetadata(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	err = s.testClient.DeleteAllMachineMetadata(testMachine.Id)
	c.Assert(err, gc.IsNil)
}
