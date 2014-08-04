package mixpanel

import (
	"testing"
)

const (
	MXP_API_KEY    = ""
	MXP_API_SECRET = ""
	MXP_TOKEN      = ""
)

func TestTrack(t *testing.T) {
	mxp := NewMixpanel(MXP_API_KEY, MXP_API_SECRET, MXP_TOKEN)

	event := Event{}
	if err := mxp.Track(&event); err != nil {
		t.Fatalf("Track failed %v", err)
	}

}

func TestUpdate(t *testing.T) {
	mxp := NewMixpanel(MXP_API_KEY, MXP_API_SECRET, MXP_TOKEN)

	update := Update{}
	if err := mxp.Update(&update); err != nil {
		t.Fatalf("Update failed %v", err)
	}
}
