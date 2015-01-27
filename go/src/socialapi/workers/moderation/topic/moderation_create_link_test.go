package topic

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestCreateLink(t *testing.T) {
	r := runner.New("test-moderation-create-link")
	err := r.Init()
	if err != nil {
		panic(err)
	}
	defer r.Close()

	SkipConvey("given a controller", t, func() {})
}
