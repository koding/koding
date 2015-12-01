package fuseklient

import (
	"github.com/jacobsa/fuse/fuseops"
	"github.com/jacobsa/fuse/fuseutil"
)

type Node interface {
	GetID() fuseops.InodeID
	GetType() fuseutil.DirentType
	GetAttrs() fuseops.InodeAttributes
	SetAttrs(fuseops.InodeAttributes)
	Forget()
	IsForgotten() bool
	Expire() error
}
