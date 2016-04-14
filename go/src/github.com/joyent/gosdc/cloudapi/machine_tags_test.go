package cloudapi_test

import gc "launchpad.net/gocheck"

func (s *LocalTests) TestAddMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	tags := map[string]string{"test": "a"}
	newTags, err := s.testClient.AddMachineTags(testMachine.Id, tags)

	c.Assert(err, gc.IsNil)
	c.Assert(tags["test"], gc.Equals, newTags["test"])
}

func (s *LocalTests) TestReplaceMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	tags, err := s.testClient.ReplaceMachineTags(testMachine.Id, map[string]string{"test": "b"})
	c.Assert(err, gc.IsNil)
	c.Assert(tags["test"], gc.Equals, "b")
}

func (s *LocalTests) TestListMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	tags, err := s.testClient.ListMachineTags(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(tags["test"], gc.Equals, "a")
}

func (s *LocalTests) TestGetMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	tag, err := s.testClient.GetMachineTag(testMachine.Id, "test")
	c.Assert(err, gc.IsNil)
	c.Assert(tag, gc.Equals, "a")
}

func (s *LocalTests) TestDeleteMachineTag(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	err = s.testClient.DeleteMachineTag(testMachine.Id, "test")
	c.Assert(err, gc.IsNil)

	tags, err := s.testClient.ListMachineTags(testMachine.Id)
	c.Assert(err, gc.IsNil)

	_, ok := tags["test"]
	c.Assert(ok, gc.Equals, false)
}

func (s *LocalTests) TestDeleteMachineTags(c *gc.C) {
	testMachine := s.createMachine(c)
	defer s.deleteMachine(c, testMachine.Id)

	_, err := s.testClient.AddMachineTags(testMachine.Id, map[string]string{"test": "a"})
	c.Assert(err, gc.IsNil)

	err = s.testClient.DeleteMachineTag(testMachine.Id, "test")
	c.Assert(err, gc.IsNil)

	tags, err := s.testClient.ListMachineTags(testMachine.Id)
	c.Assert(err, gc.IsNil)
	c.Assert(tags, gc.HasLen, 0)
}
