package models

import "time"

type PluginBundle struct {
	Id       int64
	Type     string
	OrgId    int64
	Enabled  bool
	JsonData map[string]interface{}

	Created time.Time
	Updated time.Time
}

// ----------------------
// COMMANDS

// Also acts as api DTO
type UpdatePluginBundleCmd struct {
	Type     string                 `json:"type" binding:"Required"`
	Enabled  bool                   `json:"enabled"`
	JsonData map[string]interface{} `json:"jsonData"`

	Id    int64 `json:"-"`
	OrgId int64 `json:"-"`
}

// ---------------------
// QUERIES
type GetPluginBundlesQuery struct {
	OrgId  int64
	Result []*PluginBundle
}
