package ses_test

import (
	"encoding/json"
	"gopkg.in/check.v1"

	"github.com/crowdmob/goamz/exp/ses"
)

func (s *S) TestSNSBounceNotificationUnmarshalling(c *check.C) {
	notification := ses.SNSNotification{}
	err := json.Unmarshal([]byte(SNSBounceNotification), &notification)
	c.Assert(err, check.IsNil)
	c.Assert(notification.Bounce, check.NotNil)
}

func (s *S) TestSNSComplaintNotificationUnmarshalling(c *check.C) {
	notification := ses.SNSNotification{}
	err := json.Unmarshal([]byte(SNSComplaintNotification), &notification)
	c.Assert(err, check.IsNil)
	c.Assert(notification.Complaint, check.NotNil)
}

func (s *S) TestSNSDeliveryNotificationUnmarshalling(c *check.C) {
	notification := ses.SNSNotification{}
	err := json.Unmarshal([]byte(SNSDeliveryNotification), &notification)
	c.Assert(err, check.IsNil)
	c.Assert(notification.Delivery, check.NotNil)
}
