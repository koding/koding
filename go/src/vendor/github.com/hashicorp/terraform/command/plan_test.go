package command

import (
	"bytes"
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/hashicorp/terraform/helper/copy"
	"github.com/hashicorp/terraform/terraform"
	"github.com/mitchellh/cli"
)

func TestPlan(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(testFixturePath("plan")); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestPlan_lockedState(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	testPath := testFixturePath("plan")
	unlock, err := testLockState("./testdata", filepath.Join(testPath, DefaultStateFilename))
	if err != nil {
		t.Fatal(err)
	}
	defer unlock()

	if err := os.Chdir(testPath); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{}
	if code := c.Run(args); code == 0 {
		t.Fatal("expected error")
	}

	output := ui.ErrorWriter.String()
	if !strings.Contains(output, "lock") {
		t.Fatal("command output does not look like a lock error:", output)
	}
}

func TestPlan_plan(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	planPath := testPlanFile(t, &terraform.Plan{
		Module: testModule(t, "apply"),
	})

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{planPath}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if p.RefreshCalled {
		t.Fatal("refresh should not be called")
	}
}

func TestPlan_destroy(t *testing.T) {
	originalState := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID: "bar",
						},
					},
				},
			},
		},
	}

	outPath := testTempFile(t)
	statePath := testStateFile(t, originalState)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-destroy",
		"-out", outPath,
		"-state", statePath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if !p.RefreshCalled {
		t.Fatal("refresh should be called")
	}

	plan := testReadPlan(t, outPath)
	for _, m := range plan.Diff.Modules {
		for _, r := range m.Resources {
			if !r.Destroy {
				t.Fatalf("bad: %#v", r)
			}
		}
	}
}

func TestPlan_noState(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	// Verify that refresh was called
	if p.RefreshCalled {
		t.Fatal("refresh should not be called")
	}

	// Verify that the provider was called with the existing state
	actual := strings.TrimSpace(p.DiffState.String())
	expected := strings.TrimSpace(testPlanNoStateStr)
	if actual != expected {
		t.Fatalf("bad:\n\n%s", actual)
	}
}

func TestPlan_outPath(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	tf, err := ioutil.TempFile("", "tf")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	outPath := tf.Name()
	os.Remove(tf.Name())

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	p.DiffReturn = &terraform.InstanceDiff{
		Destroy: true,
	}

	args := []string{
		"-out", outPath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	f, err := os.Open(outPath)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	defer f.Close()

	if _, err := terraform.ReadPlan(f); err != nil {
		t.Fatalf("err: %s", err)
	}
}

func TestPlan_outPathNoChange(t *testing.T) {
	originalState := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID: "bar",
						},
					},
				},
			},
		},
	}
	statePath := testStateFile(t, originalState)

	tf, err := ioutil.TempFile("", "tf")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	outPath := tf.Name()
	os.Remove(tf.Name())

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-out", outPath,
		"-state", statePath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	plan := testReadPlan(t, outPath)
	if !plan.Diff.Empty() {
		t.Fatalf("Expected empty plan to be written to plan file, got: %s", plan)
	}
}

// When using "-out" with a backend, the plan should encode the backend config
func TestPlan_outBackend(t *testing.T) {
	// Create a temporary working directory that is empty
	td := tempDir(t)
	copy.CopyDir(testFixturePath("plan-out-backend"), td)
	defer os.RemoveAll(td)
	defer testChdir(t, td)()

	// Our state
	originalState := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID: "bar",
						},
					},
				},
			},
		},
	}
	originalState.Init()

	// Setup our backend state
	dataState, srv := testBackendState(t, originalState, 200)
	defer srv.Close()
	testStateFileRemote(t, dataState)

	outPath := "foo"
	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-out", outPath,
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	plan := testReadPlan(t, outPath)
	if !plan.Diff.Empty() {
		t.Fatalf("Expected empty plan to be written to plan file, got: %s", plan)
	}

	if plan.Backend.Empty() {
		t.Fatal("should have backend info")
	}
	if !reflect.DeepEqual(plan.Backend, dataState.Backend) {
		t.Fatalf("bad: %#v", plan.Backend)
	}
}

// When using "-out" with a legacy remote state, the plan should encode
// the backend config
func TestPlan_outBackendLegacy(t *testing.T) {
	// Create a temporary working directory that is empty
	td := tempDir(t)
	copy.CopyDir(testFixturePath("plan-out-backend-legacy"), td)
	defer os.RemoveAll(td)
	defer testChdir(t, td)()

	// Our state
	originalState := &terraform.State{
		Modules: []*terraform.ModuleState{
			&terraform.ModuleState{
				Path: []string{"root"},
				Resources: map[string]*terraform.ResourceState{
					"test_instance.foo": &terraform.ResourceState{
						Type: "test_instance",
						Primary: &terraform.InstanceState{
							ID: "bar",
						},
					},
				},
			},
		},
	}
	originalState.Init()

	// Setup our legacy state
	remoteState, srv := testRemoteState(t, originalState, 200)
	defer srv.Close()
	dataState := terraform.NewState()
	dataState.Remote = remoteState
	testStateFileRemote(t, dataState)

	outPath := "foo"
	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-out", outPath,
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	plan := testReadPlan(t, outPath)
	if !plan.Diff.Empty() {
		t.Fatalf("Expected empty plan to be written to plan file, got: %s", plan)
	}

	if plan.State.Remote.Empty() {
		t.Fatal("should have remote info")
	}
}

func TestPlan_refresh(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-refresh=false",
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if p.RefreshCalled {
		t.Fatal("refresh should not be called")
	}
}

func TestPlan_state(t *testing.T) {
	// Write out some prior state
	tf, err := ioutil.TempFile("", "tf")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	statePath := tf.Name()
	defer os.Remove(tf.Name())

	originalState := testState()
	err = terraform.WriteState(originalState, tf)
	tf.Close()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-state", statePath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	// Verify that the provider was called with the existing state
	actual := strings.TrimSpace(p.DiffState.String())
	expected := strings.TrimSpace(testPlanStateStr)
	if actual != expected {
		t.Fatalf("bad:\n\n%s", actual)
	}
}

func TestPlan_stateDefault(t *testing.T) {
	originalState := testState()

	// Write the state file in a temporary directory with the
	// default filename.
	td, err := ioutil.TempDir("", "tf")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	statePath := filepath.Join(td, DefaultStateFilename)

	f, err := os.Create(statePath)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	err = terraform.WriteState(originalState, f)
	f.Close()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	// Change to that directory
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(filepath.Dir(statePath)); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	// Verify that the provider was called with the existing state
	actual := strings.TrimSpace(p.DiffState.String())
	expected := strings.TrimSpace(testPlanStateDefaultStr)
	if actual != expected {
		t.Fatalf("bad:\n\n%s", actual)
	}
}

func TestPlan_stateFuture(t *testing.T) {
	originalState := testState()
	originalState.TFVersion = "99.99.99"
	statePath := testStateFile(t, originalState)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-state", statePath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code == 0 {
		t.Fatal("should fail")
	}

	f, err := os.Open(statePath)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	newState, err := terraform.ReadState(f)
	f.Close()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	if !newState.Equal(originalState) {
		t.Fatalf("bad: %#v", newState)
	}
	if newState.TFVersion != originalState.TFVersion {
		t.Fatalf("bad: %#v", newState)
	}
}

func TestPlan_statePast(t *testing.T) {
	originalState := testState()
	originalState.TFVersion = "0.1.0"
	statePath := testStateFile(t, originalState)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		"-state", statePath,
		testFixturePath("plan"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestPlan_validate(t *testing.T) {
	// This is triggered by not asking for input so we have to set this to false
	test = false
	defer func() { test = true }()

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(testFixturePath("plan-invalid")); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{}
	if code := c.Run(args); code != 1 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	actual := ui.ErrorWriter.String()
	if !strings.Contains(actual, "cannot be computed") {
		t.Fatalf("bad: %s", actual)
	}
}

func TestPlan_vars(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	actual := ""
	p.DiffFn = func(
		info *terraform.InstanceInfo,
		s *terraform.InstanceState,
		c *terraform.ResourceConfig) (*terraform.InstanceDiff, error) {
		if v, ok := c.Config["value"]; ok {
			actual = v.(string)
		}

		return nil, nil
	}

	args := []string{
		"-var", "foo=bar",
		testFixturePath("plan-vars"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if actual != "bar" {
		t.Fatal("didn't work")
	}
}

func TestPlan_varsUnset(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	// Disable test mode so input would be asked
	test = false
	defer func() { test = true }()

	defaultInputReader = bytes.NewBufferString("bar\n")

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{
		testFixturePath("plan-vars"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestPlan_varFile(t *testing.T) {
	tmp, cwd := testCwd(t)
	defer testFixCwd(t, tmp, cwd)

	varFilePath := testTempFile(t)
	if err := ioutil.WriteFile(varFilePath, []byte(planVarFile), 0644); err != nil {
		t.Fatalf("err: %s", err)
	}

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	actual := ""
	p.DiffFn = func(
		info *terraform.InstanceInfo,
		s *terraform.InstanceState,
		c *terraform.ResourceConfig) (*terraform.InstanceDiff, error) {
		if v, ok := c.Config["value"]; ok {
			actual = v.(string)
		}

		return nil, nil
	}

	args := []string{
		"-var-file", varFilePath,
		testFixturePath("plan-vars"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if actual != "bar" {
		t.Fatal("didn't work")
	}
}

func TestPlan_varFileDefault(t *testing.T) {
	varFileDir := testTempDir(t)
	varFilePath := filepath.Join(varFileDir, "terraform.tfvars")
	if err := ioutil.WriteFile(varFilePath, []byte(planVarFile), 0644); err != nil {
		t.Fatalf("err: %s", err)
	}

	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(varFileDir); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	actual := ""
	p.DiffFn = func(
		info *terraform.InstanceInfo,
		s *terraform.InstanceState,
		c *terraform.ResourceConfig) (*terraform.InstanceDiff, error) {
		if v, ok := c.Config["value"]; ok {
			actual = v.(string)
		}

		return nil, nil
	}

	args := []string{
		testFixturePath("plan-vars"),
	}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}

	if actual != "bar" {
		t.Fatal("didn't work")
	}
}

func TestPlan_detailedExitcode(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(testFixturePath("plan")); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{"-detailed-exitcode"}
	if code := c.Run(args); code != 2 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

func TestPlan_detailedExitcode_emptyDiff(t *testing.T) {
	cwd, err := os.Getwd()
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if err := os.Chdir(testFixturePath("plan-emptydiff")); err != nil {
		t.Fatalf("err: %s", err)
	}
	defer os.Chdir(cwd)

	p := testProvider()
	ui := new(cli.MockUi)
	c := &PlanCommand{
		Meta: Meta{
			ContextOpts: testCtxConfig(p),
			Ui:          ui,
		},
	}

	args := []string{"-detailed-exitcode"}
	if code := c.Run(args); code != 0 {
		t.Fatalf("bad: %d\n\n%s", code, ui.ErrorWriter.String())
	}
}

const planVarFile = `
foo = "bar"
`

const testPlanNoStateStr = `
<not created>
`

const testPlanStateStr = `
ID = bar
Tainted = false
`

const testPlanStateDefaultStr = `
ID = bar
Tainted = false
`
