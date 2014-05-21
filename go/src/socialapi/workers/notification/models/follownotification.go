package models

type FollowNotification struct {
	// followed account
	TargetId int64
	ListerId int64
	// follower account
	NotifierId int64
}

func (n *FollowNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	return []int64{n.TargetId}, nil
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

func (n *FollowNotification) SetActorId(actorId int64) {
	n.NotifierId = actorId
}

func NewFollowNotification() *FollowNotification {
	return &FollowNotification{}
}

func (n *FollowNotification) GetDefinition() string {
	return getGenericDefinition("follower")
}

func (n *FollowNotification) GetActivity() string {
	return "started following you."
}
