package watcher

import "testing"

func TestParamsGet(t *testing.T) {
	params := NewParams()
	params.System["run"] = "statler"

	run := params.Get("run")
	if run != "statler" {
		t.Error("Expected statler but got %s in params.Get()", run)
		t.FailNow()
	}
}

func TestParamsClone(t *testing.T) {
	params := NewParams()
	params.System["run"] = "statler"

	params.CloneRun()
	watch := params.Get("watch")
	if watch != "statler" {
		t.Error("Expected statler but got %s when watch param is not set", watch)
	}

	params.System["watch"] = "waldorf"

	params.CloneRun()

	watch = params.Get("watch")
	if watch != "waldorf" {
		t.Errorf("Expected waldorf but got %s when watch param is set", watch)
	}

}

func TestPrepareArgs(t *testing.T) {
	args := []string{"watcher", "-run", "balcony", "-p", "11880", "--watch", "show", "--host", "localhost"}

	params := PrepareArgs(args)
	if len(params.Package) != 4 {
		t.Fatalf("Expected 2 parameters with their values in Package parameters but got %d", len(params.Package))
	}

	if params.Package[0] != "-p" {
		t.Errorf("Expected -p as package parameter but got %s", params.Package[0])
	}

	if params.Package[2] != "--host" {
		t.Errorf("Expected --host as package parameter but got %s", params.Package[0])
	}

	if len(params.System) != 2 {
		t.Fatalf("Expected 2 parameter with their values in System parameters but got %d", len(params.System))
	}

	if params.System["run"] != "balcony" {
		t.Errorf("Expected balcony but got %s", params.System["run"])
	}

	// TODO check this fatal error case
	// args = []string{"watcher", "-run", "balcony", "-p", "11880", "--watch"}
	// params = PrepareArgs(args)

}

func TestStripDash(t *testing.T) {
	arg := stripDash("-p")
	if arg != "p" {
		t.Errorf("Expected p but got %s in stripDash", arg)
	}

	arg = stripDash("--host")
	if arg != "host" {
		t.Errorf("Expected host but got %s in stripDash", arg)
	}

	arg = stripDash("--p")
	if arg != "p" {
		t.Errorf("Expected p but got %s in stripDash", arg)
	}

	arg = stripDash("11880")
	if arg != "11880" {
		t.Errorf("Expected 11880 but got %s in stripDash", arg)
	}

}
