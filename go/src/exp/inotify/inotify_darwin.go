package inotify

type Event struct {
	Mask   uint32
	Cookie uint32
	Name   string
}

type Watcher struct {
	Error chan error
	Event chan *Event
}

func NewWatcher() (*Watcher, error) {
	return new(Watcher), nil
}

func (w *Watcher) Close() error {
	return nil
}

func (w *Watcher) AddWatch(path string, flags uint32) error {
	return nil
}

func (w *Watcher) Watch(path string) error {
	return nil
}

func (w *Watcher) RemoveWatch(path string) error {
	return nil
}

func (e *Event) String() string {
	return ""
}

const (
	IN_DONT_FOLLOW   uint32 = 0
	IN_ONESHOT       uint32 = 0
	IN_ONLYDIR       uint32 = 0
	IN_ACCESS        uint32 = 0
	IN_ALL_EVENTS    uint32 = 0
	IN_ATTRIB        uint32 = 0
	IN_CLOSE         uint32 = 0
	IN_CLOSE_NOWRITE uint32 = 0
	IN_CLOSE_WRITE   uint32 = 0
	IN_CREATE        uint32 = 0
	IN_DELETE        uint32 = 0
	IN_DELETE_SELF   uint32 = 0
	IN_MODIFY        uint32 = 0
	IN_MOVE          uint32 = 0
	IN_MOVED_FROM    uint32 = 0
	IN_MOVED_TO      uint32 = 0
	IN_MOVE_SELF     uint32 = 0
	IN_OPEN          uint32 = 0
	IN_ISDIR         uint32 = 0
	IN_IGNORED       uint32 = 0
	IN_Q_OVERFLOW    uint32 = 0
	IN_UNMOUNT       uint32 = 0
)
