package models

import "github.com/koding/bongo"

func (nc *NotificationContent) AfterCreate() {
	bongo.B.AfterCreate(nc)
}

func (nc *NotificationContent) AfterUpdate() {
	bongo.B.AfterUpdate(nc)
}

func (nc *NotificationContent) AfterDelete() {
	bongo.B.AfterDelete(nc)
}

func NewNotificationContent() *NotificationContent {
	return &NotificationContent{}
}

func (n *NotificationContent) GetId() int64 {
	return n.Id
}

func (n NotificationContent) TableName() string {
	return "notification.notification_content"
}

// Create checks for NotificationContent using type_constant and target_id
// and creates new one if it does not exist.
func (n *NotificationContent) Create() error {
	if err := n.FindByTarget(); err != nil {
		if err != bongo.RecordNotFound {
			return err
		}
		return bongo.B.Create(n)
	}

	return nil
}

func (n *NotificationContent) One(q *bongo.Query) error {
	return bongo.B.One(n, n, q)
}

func (n *NotificationContent) ById(id int64) error {
	return bongo.B.ById(n, id)
}

func (n *NotificationContent) Some(data interface{}, q *bongo.Query) error {
	return bongo.B.Some(n, data, q)
}
