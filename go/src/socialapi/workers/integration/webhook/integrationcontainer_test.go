package webhook

import (
	"testing"

	"github.com/koding/runner"
	. "github.com/smartystreets/goconvey/convey"
)

func TestIntegrationContainersPopulate(t *testing.T) {
	r := runner.New("test")
	if err := r.Init(); err != nil {
		panic(err)
	}
	defer r.Close()

	Convey("while populating channel integrations", t, func() {
		account := createTestAccount(t)
		channel := createTestGroupChannel(t, account)
		integration := CreateTestIntegration(t)

		ci := NewChannelIntegration()
		ci.CreatorId = account.Id
		ci.ChannelId = channel.Id
		ci.GroupName = channel.GroupName
		ci.IntegrationId = integration.Id
		err := ci.Create()
		So(err, ShouldBeNil)

		Convey("it should contain all my integrations that created from a single integration", func() {
			// test for 1 channel integration
			ics := NewIntegrationContainers()
			err := ics.Populate(ci.GroupName)
			So(err, ShouldBeNil)
			So(len(ics.IntegrationContainers), ShouldEqual, 1)
			testInt := ics.IntegrationContainers[0].Integration
			So(testInt.Name, ShouldEqual, integration.Name)
			So(len(ics.IntegrationContainers[0].ChannelIntegrations), ShouldEqual, 1)
			testCi := ics.IntegrationContainers[0].ChannelIntegrations[0]
			So(testCi.Id, ShouldEqual, ci.Id)

			// test for 2 channel integrations created from 1 integration
			ci.Id = 0
			err = ci.Create()
			So(err, ShouldBeNil)

			ics = NewIntegrationContainers()
			err = ics.Populate(ci.GroupName)
			So(err, ShouldBeNil)
			So(len(ics.IntegrationContainers), ShouldEqual, 1)
			testInt = ics.IntegrationContainers[0].Integration
			So(testInt.Name, ShouldEqual, integration.Name)
			So(len(ics.IntegrationContainers[0].ChannelIntegrations), ShouldEqual, 2)

		})

		Convey("it should contain all my integrations that created from two different integrations", func() {

			secondIntegration := CreateTestIntegration(t)

			ci := NewChannelIntegration()
			ci.CreatorId = account.Id
			ci.ChannelId = channel.Id
			ci.GroupName = channel.GroupName
			ci.IntegrationId = secondIntegration.Id
			err := ci.Create()
			So(err, ShouldBeNil)

			ics := NewIntegrationContainers()
			err = ics.Populate(ci.GroupName)
			So(err, ShouldBeNil)
			So(len(ics.IntegrationContainers), ShouldEqual, 2)
			So(len(ics.IntegrationContainers[0].ChannelIntegrations), ShouldEqual, 1)
			So(len(ics.IntegrationContainers[1].ChannelIntegrations), ShouldEqual, 1)
		})
	})
}
