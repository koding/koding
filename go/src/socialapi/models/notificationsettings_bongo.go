package models

// TO-DO
//
// Are you sure to add this notification settings into the api schema
// If not , think about more for it about pros and cons
//
//~Mehmet Ali
const NotificationSettingsBongoName = "api.channel"

func (ns NotificationSettings) GetId() int64 {
	return ns.Id
}

func (ns NotificationSettings) BongoName() string {
	return NotificationSettingsBongoName
}
