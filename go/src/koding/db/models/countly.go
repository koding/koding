package models

// Countly is general container for Countly info
type Countly struct {
	APIKey string `bson:"apiKey" json:"apiKey"`
	AppKey string `bson:"appKey" json:"appKey"`
	AppID  string `bson:"appId" json:"appId"`
	UserID string `bson:"userId" json:"-"`
}

// Valid checks if countly instance is valid.
func (c *Countly) Valid() bool {
	return c != nil && c.APIKey != ""
}
