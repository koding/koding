package collaboration

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCollaborationOperations(t *testing.T) {
	r := runner.New("collaboration-operations-tests")
	err := r.Init()
	if err != nil {
		panic(err)
	}

	defer r.Close()

	Convey("while testing collaboration operations", t, func() {})
}
