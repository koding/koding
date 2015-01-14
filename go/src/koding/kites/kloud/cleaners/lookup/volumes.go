package lookup

import (
	"bytes"
	"fmt"
	"text/tabwriter"

	"github.com/mitchellh/goamz/ec2"
)

type Volumes map[string]ec2.Volume

type MultiVolumes map[*ec2.EC2]Volumes

// String representation of MultiVolumes
func (m MultiVolumes) String() string {
	fmt.Printf("\n\n")
	w := new(tabwriter.Writer)

	buf := new(bytes.Buffer)
	w.Init(buf, 0, 8, 0, '\t', 0)

	total := 0
	for client, volumes := range m {
		region := client.Region.Name
		fmt.Fprintf(w, "[%s]\t total volumes: %+v \n", region, len(volumes))
		total += len(volumes)
	}

	fmt.Fprintln(w)
	w.Flush()

	return buf.String()
}
