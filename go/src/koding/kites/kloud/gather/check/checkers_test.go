package main

import (
	"fmt"
	"os/exec"
	"testing"

	. "github.com/smartystreets/goconvey/convey"
)

func TestBinData(t *testing.T) {
	Convey("It should access assets in bindata", t, func() {
		common, err := Asset("scripts/common")
		So(err, ShouldBeNil)

		zsh, err := Asset("scripts/run-zsh_config_lines.sh")
		So(err, ShouldBeNil)

		bites := string(common) + string(zsh)

		output, err := exec.Command("bash", "-c", bites).Output()
		fmt.Println(string(output))

		So(err, ShouldBeNil)
	})
}
