package metrics

// Interface for implementations of tracker, i.e. external analytic
// services like mixpanel etc.
type tracker interface {
	Track(string, Prop) error
}

type Prop map[string]interface{}

func InitTrackers(trackers ...tracker) *Trackers {
	return &Trackers{List: trackers}
}

//----------------------------------------------------------
// Trackers
//----------------------------------------------------------

// Trackers is a multiplexer that sends events to all trackers
type Trackers struct {
	List []tracker
}

func (t *Trackers) Track(name string) error {
	err := t.TrackWithProp(name, Prop{})
	return err
}

func (t *Trackers) TrackWithProp(name string, properties Prop) error {
	for _, tracker := range t.List {
		err := tracker.Track(name, properties)
		if err != nil {
			return err
		}
	}

	return nil
}
