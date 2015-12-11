package ibm_test

import (
	"fmt"
	"os"
	"testing"
	"text/tabwriter"
	"time"

	"koding/kites/kloud/api/ibm"

	slclient "github.com/maximilien/softlayer-go/client"
)

var opts = &ibm.Options{}

func init() {
	os.Unsetenv("SL_GO_NON_VERBOSE")

	opts.SLClient = slclient.NewSoftLayerClient(
		os.Getenv("KLOUD_TESTACCOUNT_SLUSERNAME"),
		os.Getenv("KLOUD_TESTACCOUNT_SLAPIKEY"),
	)
}

func nonil(err ...error) error {
	for _, e := range err {
		if e != nil {
			return e
		}
	}
	return nil
}

func validate(t ibm.Templates) error {
	for i, template := range t {
		if template.GlobalID == "" {
			return fmt.Errorf("template[%d].GlobalID is empty", i)
		}
	}
	return nil
}

func TestClient(t *testing.T) {
	c := ibm.NewSoftlayerWithOptions(opts)
	f := &ibm.Filter{
		Datacenter: "sjc01",
	}
	d := time.Now()
	templates, err := c.TemplatesByFilter(f)
	if err = nonil(err, validate(templates)); err != nil {
		t.Fatal(err)
	}
	reqDur := time.Now().Sub(d)
	// Even though the following should return single result, it has
	// "Softlayer-Total-Items: 2" and single item in the payload.
	// The item, however, has empty Datacenters field.
	// Does objectFilter zeroes it?
	d = time.Now()
	xtemplates, err := c.XTemplatesByFilter(f)
	if err = nonil(err, validate(xtemplates)); err != nil {
		t.Fatal(err)
	}
	xreqDur := time.Now().Sub(d)
	t.Logf("[TEST] filtering took: client-side=%s, server-side=%s", reqDur, xreqDur)
	if len(templates) != len(xtemplates) {
		t.Fatalf("want len(templates)=%d == len(xtemplates)=%d\n", len(templates), len(xtemplates))
	}
}

func TestLookupImage(t *testing.T) {
	c := ibm.NewSoftlayerWithOptions(opts)
	f := &ibm.Filter{
		Tags: ibm.Tags{
			"Name": "koding-stable",
		},
	}
	images, err := c.TemplatesByFilter(f)
	if err != nil {
		t.Fatal(err)
	}
	w := &tabwriter.Writer{}
	w.Init(os.Stdout, 0, 8, 0, '\t', 0)
	fmt.Fprintln(w, "ID\tGlobalID\tTags\tDatacenter\tDatacenters")
	for _, image := range images {
		fmt.Fprintf(w, "%d\t%s\t%s\t%v\t%v\n", image.ID, image.GlobalID,
			image.Tags, image.Datacenter, image.Datacenters)
	}
	w.Flush()
}
