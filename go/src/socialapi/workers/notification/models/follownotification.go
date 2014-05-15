package models

type FollowNotification struct {
	// followed account
	TargetId int64
	ListerId int64
	// follower account
	NotifierId int64
}

func (n *FollowNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	users := make([]int64, 0)
	return append(users, n.TargetId), nil
}

func (n *FollowNotification) GetType() string {
	return NotificationContent_TYPE_FOLLOW
}

func (n *FollowNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *FollowNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
}

func (n *FollowNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *FollowNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *FollowNotification) GetActorId() int64 {
	return n.NotifierId
}

func NewFollowNotification() *FollowNotification {
	return &FollowNotification{}
}
