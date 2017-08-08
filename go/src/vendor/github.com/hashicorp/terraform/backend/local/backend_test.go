package local

import (
	"errors"
	"io/ioutil"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/hashicorp/terraform/backend"
	"github.com/hashicorp/terraform/state"
	"github.com/hashicorp/terraform/terraform"
)

func TestLocal_impl(t *testing.T) {
	var _ backend.Enhanced = new(Local)
	var _ backend.Local = new(Local)
	var _ backend.CLI = new(Local)
}

func TestLocal_backend(t *testing.T) {
	defer testTmpDir(t)()
	b := &Local{}
	backend.TestBackend(t, b, b)
}

func checkState(t *testing.T, path, expected string) {
	// Read the state
	f, err := os.Open(path)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	state, err := terraform.ReadState(f)
	f.Close()
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	actual := strings.TrimSpace(state.String())
	expected = strings.TrimSpace(expected)
	if actual != expected {
		t.Fatalf("state does not match! actual:\n%s\n\nexpected:\n%s", actual, expected)
	}
}

func TestLocal_StatePaths(t *testing.T) {
	b := &Local{}

	// Test the defaults
	path, out, back := b.StatePaths("")

	if path != DefaultStateFilename {
		t.Fatalf("expected %q, got %q", DefaultStateFilename, path)
	}

	if out != DefaultStateFilename {
		t.Fatalf("expected %q, got %q", DefaultStateFilename, out)
	}

	dfltBackup := DefaultStateFilename + DefaultBackupExtension
	if back != dfltBackup {
		t.Fatalf("expected %q, got %q", dfltBackup, back)
	}

	// check with env
	testEnv := "test_env"
	path, out, back = b.StatePaths(testEnv)

	expectedPath := filepath.Join(DefaultEnvDir, testEnv, DefaultStateFilename)
	expectedOut := expectedPath
	expectedBackup := expectedPath + DefaultBackupExtension

	if path != expectedPath {
		t.Fatalf("expected %q, got %q", expectedPath, path)
	}

	if out != expectedOut {
		t.Fatalf("expected %q, got %q", expectedOut, out)
	}

	if back != expectedBackup {
		t.Fatalf("expected %q, got %q", expectedBackup, back)
	}

}

func TestLocal_addAndRemoveStates(t *testing.T) {
	defer testTmpDir(t)()
	dflt := backend.DefaultStateName
	expectedStates := []string{dflt}

	b := &Local{}
	states, err := b.States()
	if err != nil {
		t.Fatal(err)
	}

	if !reflect.DeepEqual(states, expectedStates) {
		t.Fatalf("expected []string{%q}, got %q", dflt, states)
	}

	expectedA := "test_A"
	if _, err := b.State(expectedA); err != nil {
		t.Fatal(err)
	}

	states, err = b.States()
	if err != nil {
		t.Fatal(err)
	}

	expectedStates = append(expectedStates, expectedA)
	if !reflect.DeepEqual(states, expectedStates) {
		t.Fatalf("expected %q, got %q", expectedStates, states)
	}

	expectedB := "test_B"
	if _, err := b.State(expectedB); err != nil {
		t.Fatal(err)
	}

	states, err = b.States()
	if err != nil {
		t.Fatal(err)
	}

	expectedStates = append(expectedStates, expectedB)
	if !reflect.DeepEqual(states, expectedStates) {
		t.Fatalf("expected %q, got %q", expectedStates, states)
	}

	if err := b.DeleteState(expectedA); err != nil {
		t.Fatal(err)
	}

	states, err = b.States()
	if err != nil {
		t.Fatal(err)
	}

	expectedStates = []string{dflt, expectedB}
	if !reflect.DeepEqual(states, expectedStates) {
		t.Fatalf("expected %q, got %q", expectedStates, states)
	}

	if err := b.DeleteState(expectedB); err != nil {
		t.Fatal(err)
	}

	states, err = b.States()
	if err != nil {
		t.Fatal(err)
	}

	expectedStates = []string{dflt}
	if !reflect.DeepEqual(states, expectedStates) {
		t.Fatalf("expected %q, got %q", expectedStates, states)
	}

	if err := b.DeleteState(dflt); err == nil {
		t.Fatal("expected error deleting default state")
	}
}

// a local backend which returns sentinel errors for NamedState methods to
// verify it's being called.
type testDelegateBackend struct {
	*Local

	// return a sentinel error on these calls
	stateErr  bool
	statesErr bool
	deleteErr bool
}

var errTestDelegateState = errors.New("State called")
var errTestDelegateStates = errors.New("States called")
var errTestDelegateDeleteState = errors.New("Delete called")

func (b *testDelegateBackend) State(name string) (state.State, error) {
	if b.stateErr {
		return nil, errTestDelegateState
	}
	s := &state.LocalState{
		Path:    "terraform.tfstate",
		PathOut: "terraform.tfstate",
	}
	return s, nil
}

func (b *testDelegateBackend) States() ([]string, error) {
	if b.statesErr {
		return nil, errTestDelegateStates
	}
	return []string{"default"}, nil
}

func (b *testDelegateBackend) DeleteState(name string) error {
	if b.deleteErr {
		return errTestDelegateDeleteState
	}
	return nil
}

// verify that the MultiState methods are dispatched to the correct Backend.
func TestLocal_multiStateBackend(t *testing.T) {
	// assign a separate backend where we can read the state
	b := &Local{
		Backend: &testDelegateBackend{
			stateErr:  true,
			statesErr: true,
			deleteErr: true,
		},
	}

	if _, err := b.State("test"); err != errTestDelegateState {
		t.Fatal("expected errTestDelegateState, got:", err)
	}

	if _, err := b.States(); err != errTestDelegateStates {
		t.Fatal("expected errTestDelegateStates, got:", err)
	}

	if err := b.DeleteState("test"); err != errTestDelegateDeleteState {
		t.Fatal("expected errTestDelegateDeleteState, got:", err)
	}
}

// verify that a remote state backend is always wrapped in a BackupState
func TestLocal_remoteStateBackup(t *testing.T) {
	// assign a separate backend to mock a remote state backend
	b := &Local{
		Backend: &testDelegateBackend{},
	}

	s, err := b.State("default")
	if err != nil {
		t.Fatal(err)
	}

	bs, ok := s.(*state.BackupState)
	if !ok {
		t.Fatal("remote state is not backed up")
	}

	if bs.Path != DefaultStateFilename+DefaultBackupExtension {
		t.Fatal("bad backup location:", bs.Path)
	}

	// do the same with a named state, which should use the local env directories
	s, err = b.State("test")
	if err != nil {
		t.Fatal(err)
	}

	bs, ok = s.(*state.BackupState)
	if !ok {
		t.Fatal("remote state is not backed up")
	}

	if bs.Path != filepath.Join(DefaultEnvDir, "test", DefaultStateFilename+DefaultBackupExtension) {
		t.Fatal("bad backup location:", bs.Path)
	}
}

// change into a tmp dir and return a deferable func to change back and cleanup
func testTmpDir(t *testing.T) func() {
	tmp, err := ioutil.TempDir("", "tf")
	if err != nil {
		t.Fatal(err)
	}

	old, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}

	if err := os.Chdir(tmp); err != nil {
		t.Fatal(err)
	}

	return func() {
		// ignore errors and try to clean up
		os.Chdir(old)
		os.RemoveAll(tmp)
	}
}
