package models

import "errors"

type GroupNotification struct {
	TargetId     int64
	ListerId     int64
	OwnerId      int64
	NotifierId   int64
	TypeConstant string
	Admins       []int64
}

// TODO fetch group admins
func (n *GroupNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	if len(n.Admins) == 0 {
		return nil, errors.New("admins cannot be empty")
	}

	return n.Admins, nil
}

func (n *GroupNotification) GetType() string {
	return n.TypeConstant
}

func (n *GroupNotification) GetTargetId() int64 {
	return n.TargetId
}

// fetch notifiers
func (n *GroupNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	actors := filterActors(naList, n.ListerId)

	return prepareActorContainer(actors), nil
}

func (n *GroupNotification) SetTargetId(targetId int64) {
	n.TargetId = targetId
}

func (n *GroupNotification) SetListerId(listerId int64) {
	n.ListerId = listerId
}

func (n *GroupNotification) GetActorId() int64 {
	return n.NotifierId
}

func (n *GroupNotification) SetActorId(actorId int64) {
	n.NotifierId = actorId
}

func NewGroupNotification(typeConstant string) *GroupNotification {
	return &GroupNotification{TypeConstant: typeConstant}
}

func (n *GroupNotification) GetDefinition() string {
	return getGenericDefinition(n.TypeConstant)
}

func (n *GroupNotification) GetActivity() string {
	var action string
	if n.TypeConstant == NotificationContent_TYPE_JOIN {
		action = "joined"
	} else {
		action = "left"
	}

	return "has " + action + " your group."
}
