package command

import (
	"os"

	"github.com/mitchellh/cli"
)

var DefaultUi = kloudUi()

func kloudUi() cli.Ui {
	basicUi := &cli.BasicUi{
		Reader:      os.Stdin,
		Writer:      os.Stdout,
		ErrorWriter: os.Stdout,
	}

	coloredUi := &cli.ColoredUi{
		OutputColor: cli.UiColorGreen,
		InfoColor:   cli.UiColorYellow,
		ErrorColor:  cli.UiColorRed,
		Ui:          basicUi,
	}

	return coloredUi

}
