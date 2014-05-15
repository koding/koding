package models

type MentionNotification struct {
	TargetId   int64
	ListerId   int64
	NotifierId int64
}

func (m *MentionNotification) GetNotifiedUsers(notificationContentId int64) ([]int64, error) {
	var notifiees []int64

	return notifiees, nil
}

func (m *MentionNotification) GetType() string {
	return NotificationContent_TYPE_MENTION
}

func (m *MentionNotification) GetTargetId() int64 {
	return m.TargetId
}

func (m *MentionNotification) SetTargetId(targetId int64) {
	m.TargetId = targetId
}

func (m *MentionNotification) FetchActors(naList []NotificationActivity) (*ActorContainer, error) {
	actors := filterActors(naList, m.ListerId)

	return prepareActorContainer(actors), nil
}

func (m *MentionNotification) SetListerId(listerId int64) {
	m.ListerId = listerId
}

func (m *MentionNotification) GetActorId() int64 {
	return m.NotifierId
}

func NewMentionNotification() *MentionNotification {
	return &MentionNotification{}
}
