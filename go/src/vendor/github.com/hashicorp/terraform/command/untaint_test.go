package command

import (
	"os"
	"strings"
	"testing"

	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
)

func TestUntaint(t *testing.T) {
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-state", statePath,
		"test_instance.foo",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	expected := strings.TrimSpace(`
test_instance.foo:
  ID = bar
	`)
	testStateOutput(t, statePath, expected)
}

func TestUntaint_lockedState(t *testing.T) {
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, state)
	unlock, err := testLockState("./testdata", statePath)
	if err != nil {
		t.Fatal(err)
	}
	defer unlock()

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-state", statePath,
		"test_instance.foo",
	}
	if code := c.Run(args); code == 0 {
		t.Fatal("expected error")
	}

	output := ui.ErrorWriter.String()
	if !strings.Contains(output, "lock") {
		t.Fatal("command output does not look like a lock error:", output)
	}
}

func TestUntaint_backup(t *testing.T) {
	// Get a temp cwd
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	// Write the temp state
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	path := testStateFileDefault(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"test_instance.foo",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	// Backup is still tainted
	testStateOutput(t, path+".backup", strings.TrimSpace(`
test_instance.foo: (tainted)
  ID = bar
	`))

	// State is untainted
	testStateOutput(t, path, strings.TrimSpace(`
test_instance.foo:
  ID = bar
	`))
}

func TestUntaint_backupDisable(t *testing.T) {
	// Get a temp cwd
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	// Write the temp state
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	path := testStateFileDefault(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-backup", "-",
		"test_instance.foo",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if _, err := os.Stat(path + ".backup"); err == nil {
		t.Fatal("backup path should not exist")
	}

	testStateOutput(t, path, strings.TrimSpace(`
test_instance.foo:
  ID = bar
	`))
}

func TestUntaint_badState(t *testing.T) {
	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-state", "i-should-not-exist-ever",
		"foo",
	}
	if code := c.Run(args); code != 1 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestUntaint_defaultState(t *testing.T) {
	// Get a temp cwd
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	// Write the temp state
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	path := testStateFileDefault(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"test_instance.foo",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	testStateOutput(t, path, strings.TrimSpace(`
test_instance.foo:
  ID = bar
	`))
}

func TestUntaint_missing(t *testing.T) {
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-state", statePath,
		"test_instance.bar",
	}
	if code := c.Run(args); code == 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.OutputWriter.String())
	}
}

func TestUntaint_missingAllow(t *testing.T) {
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-allow-missing",
		"-state", statePath,
		"test_instance.bar",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestUntaint_stateOut(t *testing.T) {
	// Get a temp cwd
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	// Write the temp state
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	path := testStateFileDefault(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-state-out", "foo",
		"test_instance.foo",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	testStateOutput(t, path, strings.TrimSpace(`
test_instance.foo: (tainted)
  ID = bar
	`))
	testStateOutput(t, "foo", strings.TrimSpace(`
test_instance.foo:
  ID = bar
	`))
}

func TestUntaint_module(t *testing.T) {
	state := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
			&terraform.ModuleState{
				Path: []string{"root", "child"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.blah": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID:      "bar",
							Tainted: true,
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, state)

	ui := new(cli.MockUi)
	c := &UntaintCommand{
		Meta: Meta{
			Ui: ui,
		},
	}

	args := []string{
		"-module=child",
		"-state", statePath,
		"test_instance.blah",
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	testStateOutput(t, statePath, strings.TrimSpace(`
test_instance.foo: (tainted)
  ID = bar

module.child:
  test_instance.blah:
    ID = bar
	`))
}
