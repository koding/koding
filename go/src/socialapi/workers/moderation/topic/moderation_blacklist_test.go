package topic

import (
	"socialapi/workers/common/runner"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestBlackList(t *testing.T) {
	r := runner.New("test-moderation-blacklist")
	err := r.Init()
	if err != nil {
		panic(err)
	}
	defer r.Close()

	SkipConvey("given a controller", t, func() {})
}
