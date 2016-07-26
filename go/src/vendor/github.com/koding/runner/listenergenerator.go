package runner

import "github.com/koding/bongo"

type ListenerHandler struct {
	model      bongo.Modellable
	eventName  string
	handleFunc interface{}
	runner     *Runner
}

func (r *Runner) Register(m bongo.Modellable) *ListenerHandler {
	return &ListenerHandler{
		model:  m,
		runner: r,
	}
}

func (l *ListenerHandler) OnUpdate() *ListenerHandler {
	return l.On("updated")
}

func (l *ListenerHandler) OnDelete() *ListenerHandler {
	return l.On("deleted")
}

func (l *ListenerHandler) OnCreate() *ListenerHandler {
	return l.On("created")
}

func (l *ListenerHandler) On(e string) *ListenerHandler {
	l.eventName = e
	return l
}

func (l *ListenerHandler) Handle(h interface{}) {
	l.runner.ListenFor(
		l.model.BongoName()+"_"+l.eventName,
		h,
	)
}
