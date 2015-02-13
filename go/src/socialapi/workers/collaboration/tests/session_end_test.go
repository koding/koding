package collaboration

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCollaborationSesionEnd(t *testing.T) {
	r := runner.New("collaboration-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	Convey("while testing collaboration session end", t, func() {
		Convey("we should be able to create a doc on google drive", func() {
			Convey("we should be able to delete a created doc", func() {
				Convey("deleting an already deleted doc should not give error", func() {
				})
			})
		})

		Convey("trying to delete a non-existing doc should not give error", func() {
		})
	})
}
