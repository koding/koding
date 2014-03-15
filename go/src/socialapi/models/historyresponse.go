package models

type HistoryResponse struct {
	MessageList []ChannelMessage `json:"messageList"`
	UnreadCount int              `json:"unreadCount"`
	// To          time.Time        `json:"to,omitempty"`
	// From        time.Time        `json:"from,omitempty"`
}

func NewHistoryResponse() *HistoryResponse {
	return &HistoryResponse{}
}
