// Package systemd/control interacts with systemd units.
package control

import (
	"fmt"
	"io"
	"strconv"
	"strings"
	"text/tabwriter"

	dbus "github.com/remyoudompheng/go-dbus"
)

type UnitInfo struct {
	Id          string
	Description string
	LoadState   string
	ActiveState string
	SubState    string
	Following   string
	UnitPath    string
	JobId       uint32
	JobType     string
	JobPath     string
}

func ListUnits(bus *dbus.Connection) (infos []UnitInfo, err error) {
	fn, err := bus.
		Object("org.freedesktop.systemd1", "/org/freedesktop/systemd1").
		Interface("org.freedesktop.systemd1.Manager").
		Method("ListUnits")
	if err != nil {
		return nil, err
	}
	reply, err := bus.Invoke(fn)
	if err == nil {
		err = reply.Unmarshal(&infos)
	}
	return infos, err
}

func PrintUnits(w io.Writer, infos []UnitInfo) {
	tw := tabwriter.NewWriter(w, 0, 8, 1, ' ', 0)
	fmt.Fprintf(tw, "UNIT\tLOAD\tACTIVE\tSUB\tJOB\tDESCRIPTION\n")
	for _, info := range infos {
		var jobId string
		if info.JobId > 0 {
			jobId = strconv.FormatInt(int64(info.JobId), 10)
		}
		id := strings.Replace(info.Id, "\\x2d", "-", -1)
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\n",
			id, info.LoadState, info.ActiveState, info.SubState, jobId, info.Description)
	}
	tw.Flush()
}
