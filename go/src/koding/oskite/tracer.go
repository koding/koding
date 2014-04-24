// +build linux

package oskite

import (
	kitednode "github.com/koding/kite/dnode"
	"koding/tools/dnode"
	"koding/tools/tracer"
)

type progresser interface {
	Enabled() bool
	Call(v interface{})
}

type vmParams struct {
	Destroy    bool
	GroupId    string
	OnProgress dnode.Callback
}

type vmParamsNew struct {
	Destroy    bool
	GroupId    string
	OnProgress kitednode.Function
}

func (v *vmParams) Enabled() bool            { return v.OnProgress != nil }
func (v *vmParams) Trace(msg tracer.Message) { v.OnProgress(msg) }

func (v *vmParamsNew) Enabled() bool            { return v.OnProgress.IsValid() }
func (v *vmParamsNew) Trace(msg tracer.Message) { v.OnProgress.Call(msg) }
