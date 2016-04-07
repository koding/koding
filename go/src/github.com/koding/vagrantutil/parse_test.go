package vagrantutil

import "testing"

const version174 = `
1459267732,,version-installed,1.7.4
1459267732,,version-latest,1.8.1
`

const version181 = `
1459268273,,ui,output,Installed Version: 1.8.1
1459268273,,version-installed,1.8.1
1459268273,,ui,output,Latest Version: 1.8.1
1459268273,,version-latest,1.8.1
1459268273,,ui,success, \nYou're running an up-to-date version of Vagrant!
`

func TestParseRecordsAndData(t *testing.T) {
	cases := []struct {
		raw string
		ver string
	}{
		{version174, "1.7.4"}, // i=0
		{version181, "1.8.1"}, // i=1
	}

	for i, cas := range cases {
		rec, err := parseRecords(cas.raw)
		if err != nil {
			t.Errorf("%d: parseRecords()=%s", i, err)
			continue
		}

		ver, err := parseData(rec, "version-installed")
		if err != nil {
			t.Errorf("%d: parseData()=%d", i, err)
			continue
		}

		if ver != cas.ver {
			t.Errorf("%d: got %q, want %q", ver, cas.ver)
		}
	}
}
