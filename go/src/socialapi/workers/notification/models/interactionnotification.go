package models

type InteractionNotification struct {
	TargetId     int64
	TypeConstant string
	ListerId     int64
	NotifierId   int64
	OwnerId      int64
}

func (n *InteractionNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	return fetchNotifiedUsers(notificationContentId)
}

func (n *InteractionNotification) GetType() string {
	return n.TypeConstant
}

func (n *InteractionNotification) GetTargetId() int64 {
	return n.TargetId
}

func (n *InteractionNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *InteractionNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	// filter obsolete activities and user's own activities
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
}

func (n *InteractionNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *InteractionNotification) GetActorId() int64 {
	return n.NotifierId
}

func (n *InteractionNotification) SetActorId(actorId int64) {
	n.NotifierId = actorId
}

func NewInteractionNotification(notificationType string) *InteractionNotification {
	return &InteractionNotification{TypeConstant: notificationType}
}

func (n *InteractionNotification) GetDefinition() string {
	return getGenericDefinition(n.TypeConstant)
}

func (n *InteractionNotification) GetActivity() string {
	return n.TypeConstant + "d your"
}
