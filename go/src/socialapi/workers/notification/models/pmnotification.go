package models

type PMNotification struct {
	TargetId   int64
	NotifierId int64
	ListerId   int64
}

func (n *PMNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	return fetchNotifiedUsers(notificationContentId)
}

func (n *PMNotification) GetType() string {
	return NotificationContent_TYPE_PM
}

func (n *PMNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *PMNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *PMNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	// filter obsolete activities and user's own activities
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
}

func (n *PMNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *PMNotification) GetActorId() int64 {
	return n.NotifierId
}

func (n *PMNotification) SetActorId(actorId int64) {
	n.NotifierId = actorId
}

func NewPMNotification() *PMNotification {
	return &PMNotification{}
}

func (n *PMNotification) GetDefinition() string {
	return "private message"
}

func (n *PMNotification) GetActivity() string {
	return "send you a"
}
