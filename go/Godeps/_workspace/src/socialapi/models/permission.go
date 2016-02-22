package models

import (
	"time"

	"github.com/koding/bongo"
)

const (
	Permission_ROLE_SUPERADMIN = "superadmin"
	Permission_ROLE_ADMIN      = "admin"
	Permission_ROLE_MODERATOR  = "moderator"
	Permission_ROLE_MEMBER     = "member"
	Permission_ROLE_GUEST      = "guest"
)

const (
	Permission_STATUS_ALLOWED    = "allowed"
	Permission_STATUS_DISALLOWED = "disallowed"
)

type PermissionResponse struct {
	Defaults []*Permission
	Context  []*Permission
}

type Permission struct {
	// unique identifier of the channel
	Id int64 `json:"id,string"`

	// name of the permission
	Name string `json:"name"`

	// Id of the channel
	ChannelId int64 `json:"channelId,string"       sql:"NOT NULL"`

	// admin, moderator, member, guest
	RoleConstant string `json:"roleConstant"`

	// Status of the permission in the channel
	// Allowed/Disallowed
	StatusConstant string `json:"statusConstant"   sql:"NOT NULL;TYPE:VARCHAR(100);"`

	// Creation date of permission
	CreatedAt time.Time `json:"createdAt"          sql:"NOT NULL"`

	// Modification date of the permission
	UpdatedAt time.Time `json:"updatedAt"          sql:"NOT NULL"`
}

func NewPermission() *Permission {
	return &Permission{}
}

func (p *Permission) FetchStatus() (string, error) {
	if p.ChannelId == 0 {
		// todo return default permission
		return Permission_STATUS_ALLOWED, nil
	}

	if p.RoleConstant == "" {
		// implicitly set role as guest, if not set
		p.RoleConstant = Permission_ROLE_GUEST
	}

	selector := map[string]interface{}{
		"channel_id":    p.ChannelId,
		"role_constant": p.RoleConstant,
	}

	err := p.One(bongo.NewQS(selector))
	if err != nil && err != bongo.RecordNotFound {
		return "", err
	}

	if err == bongo.RecordNotFound {
		// todo return default permission
		return Permission_STATUS_ALLOWED, nil
	}

	return p.StatusConstant, nil
}

func (p *Permission) EnsureAllowance() error {
	status, err := p.FetchStatus()
	if err != nil {
		return err
	}

	if status == Permission_STATUS_ALLOWED {
		return nil
	}

	return ErrAccessDenied
}
