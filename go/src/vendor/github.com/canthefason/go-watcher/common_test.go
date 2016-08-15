package watcher

import "testing"

func TestParamsGet(t *testing.T) {
	params := NewParams()
	params.Watcher["run"] = "statler"

	run := params.Get("run")
	if run != "statler" {
		t.Error("Expected statler but got %s in params.Get()", run)
		t.FailNow()
	}
}

func TestParamsClone(t *testing.T) {
	params := NewParams()
	params.Watcher["run"] = "statler"

	params.cloneRunFlag()
	watch := params.Get("watch")
	if watch != "statler" {
		t.Error("Expected statler but got %s when watch param is not set", watch)
	}

	params.Watcher["watch"] = "waldorf"

	params.cloneRunFlag()

	watch = params.Get("watch")
	if watch != "waldorf" {
		t.Errorf("Expected waldorf but got %s when watch param is set", watch)
	}

}

func TestPrepareArgs(t *testing.T) {
	args := []string{"watcher", "-run", "balcony", "-p", "11880", "--watch", "show", "--host", "localhost"}

	params := ParseArgs(args)
	if len(params.Package) != 4 {
		t.Fatalf("Expected 2 parameters with their values in Package parameters but got %d", len(params.Package))
	}

	if params.Package[0] != "-p" {
		t.Errorf("Expected -p as package parameter but got %s", params.Package[0])
	}

	if params.Package[2] != "--host" {
		t.Errorf("Expected --host as package parameter but got %s", params.Package[0])
	}

	if len(params.Watcher) != 2 {
		t.Fatalf("Expected 2 parameter with their values in System parameters but got %d", len(params.Watcher))
	}

	if params.Watcher["run"] != "balcony" {
		t.Errorf("Expected balcony but got %s", params.Watcher["run"])
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

func TestExistIn(t *testing.T) {
	input := []string{"a", "b", "c"}

	if !existIn("c", input) {
		t.Errorf("expected true, got false")
	}

	if existIn("d", input) {
		t.Errorf("expected false, got true")
	}
}
