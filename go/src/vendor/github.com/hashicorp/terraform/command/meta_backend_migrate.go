package command

import (
	"context"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/hashicorp/terraform/backend"
	"github.com/hashicorp/terraform/command/clistate"
	"github.com/hashicorp/terraform/state"
	"github.com/hashicorp/terraform/terraform"
)

// backendMigrateState handles migrating (copying) state from one backend
// to another. This function handles asking the user for confirmation
// as well as the copy itself.
//
// This function can handle all scenarios of state migration regardless
// of the existence of state in either backend.
//
// After migrating the state, the existing state in the first backend
// remains untouched.
//
// This will attempt to lock both states for the migration.
func (m *Meta) backendMigrateState(opts *backendMigrateOpts) error {
	// We need to check what the named state status is. If we're converting
	// from multi-state to single-state for example, we need to handle that.
	var oneSingle, twoSingle bool
	oneStates, err := opts.One.States()
	if err == backend.ErrNamedStatesNotSupported {
		oneSingle = true
		err = nil
	}
	if err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateLoadStates), opts.OneType, err)
	}

	_, err = opts.Two.States()
	if err == backend.ErrNamedStatesNotSupported {
		twoSingle = true
		err = nil
	}
	if err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateLoadStates), opts.TwoType, err)
	}

	// Setup defaults
	opts.oneEnv = backend.DefaultStateName
	opts.twoEnv = backend.DefaultStateName
	opts.force = m.forceInitCopy

	// Determine migration behavior based on whether the source/destination
	// supports multi-state.
	switch {
	// Single-state to single-state. This is the easiest case: we just
	// copy the default state directly.
	case oneSingle && twoSingle:
		return m.backendMigrateState_s_s(opts)

	// Single-state to multi-state. This is easy since we just copy
	// the default state and ignore the rest in the destination.
	case oneSingle && !twoSingle:
		return m.backendMigrateState_s_s(opts)

	// Multi-state to single-state. If the source has more than the default
	// state this is complicated since we have to ask the user what to do.
	case !oneSingle && twoSingle:
		// If the source only has one state and it is the default,
		// treat it as if it doesn't support multi-state.
		if len(oneStates) == 1 && oneStates[0] == backend.DefaultStateName {
			return m.backendMigrateState_s_s(opts)
		}

		return m.backendMigrateState_S_s(opts)

	// Multi-state to multi-state. We merge the states together (migrating
	// each from the source to the destination one by one).
	case !oneSingle && !twoSingle:
		// If the source only has one state and it is the default,
		// treat it as if it doesn't support multi-state.
		if len(oneStates) == 1 && oneStates[0] == backend.DefaultStateName {
			return m.backendMigrateState_s_s(opts)
		}

		return m.backendMigrateState_S_S(opts)
	}

	return nil
}

//-------------------------------------------------------------------
// State Migration Scenarios
//
// The functions below cover handling all the various scenarios that
// can exist when migrating state. They are named in an immediately not
// obvious format but is simple:
//
// Format: backendMigrateState_s1_s2[_suffix]
//
// When s1 or s2 is lower case, it means that it is a single state backend.
// When either is uppercase, it means that state is a multi-state backend.
// The suffix is used to disambiguate multiple cases with the same type of
// states.
//
//-------------------------------------------------------------------

// Multi-state to multi-state.
func (m *Meta) backendMigrateState_S_S(opts *backendMigrateOpts) error {
	// Ask the user if they want to migrate their existing remote state
	migrate, err := m.confirm(&terraform.InputOpts{
		Id: "backend-migrate-multistate-to-multistate",
		Query: fmt.Sprintf(
			"Do you want to migrate all environments to %q?",
			opts.TwoType),
		Description: fmt.Sprintf(
			strings.TrimSpace(inputBackendMigrateMultiToMulti),
			opts.OneType, opts.TwoType),
	})
	if err != nil {
		return fmt.Errorf(
			"Error asking for state migration action: %s", err)
	}
	if !migrate {
		return fmt.Errorf("Migration aborted by user.")
	}

	// Read all the states
	oneStates, err := opts.One.States()
	if err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateLoadStates), opts.OneType, err)
	}

	// Sort the states so they're always copied alphabetically
	sort.Strings(oneStates)

	// Go through each and migrate
	for _, name := range oneStates {
		// Copy the same names
		opts.oneEnv = name
		opts.twoEnv = name

		// Force it, we confirmed above
		opts.force = true

		// Perform the migration
		if err := m.backendMigrateState_s_s(opts); err != nil {
			return fmt.Errorf(strings.TrimSpace(
				errMigrateMulti), name, opts.OneType, opts.TwoType, err)
		}
	}

	return nil
}

// Multi-state to single state.
func (m *Meta) backendMigrateState_S_s(opts *backendMigrateOpts) error {
	currentEnv := m.Env()

	migrate := opts.force
	if !migrate {
		var err error
		// Ask the user if they want to migrate their existing remote state
		migrate, err = m.confirm(&terraform.InputOpts{
			Id: "backend-migrate-multistate-to-single",
			Query: fmt.Sprintf(
				"Destination state %q doesn't support environments (named states).\n"+
					"Do you want to copy only your current environment?",
				opts.TwoType),
			Description: fmt.Sprintf(
				strings.TrimSpace(inputBackendMigrateMultiToSingle),
				opts.OneType, opts.TwoType, currentEnv),
		})
		if err != nil {
			return fmt.Errorf(
				"Error asking for state migration action: %s", err)
		}
	}

	if !migrate {
		return fmt.Errorf("Migration aborted by user.")
	}

	// Copy the default state
	opts.oneEnv = currentEnv

	// now switch back to the default env so we can acccess the new backend
	m.SetEnv(backend.DefaultStateName)

	return m.backendMigrateState_s_s(opts)
}

// Single state to single state, assumed default state name.
func (m *Meta) backendMigrateState_s_s(opts *backendMigrateOpts) error {
	stateOne, err := opts.One.State(opts.oneEnv)
	if err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateSingleLoadDefault), opts.OneType, err)
	}
	if err := stateOne.RefreshState(); err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateSingleLoadDefault), opts.OneType, err)
	}

	stateTwo, err := opts.Two.State(opts.twoEnv)
	if err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateSingleLoadDefault), opts.TwoType, err)
	}
	if err := stateTwo.RefreshState(); err != nil {
		return fmt.Errorf(strings.TrimSpace(
			errMigrateSingleLoadDefault), opts.TwoType, err)
	}

	// Check if we need migration at all.
	// This is before taking a lock, because they may also correspond to the same lock.
	one := stateOne.State()
	two := stateTwo.State()

	// no reason to migrate if the state is already there
	if one.Equal(two) {
		// Equal isn't identical; it doesn't check lineage.
		if one != nil && two != nil && one.Lineage == two.Lineage {
			return nil
		}
	}

	if m.stateLock {
		lockCtx, cancel := context.WithTimeout(context.Background(), m.stateLockTimeout)
		defer cancel()

		lockInfoOne := state.NewLockInfo()
		lockInfoOne.Operation = "migration"
		lockInfoOne.Info = "source state"

		lockIDOne, err := clistate.Lock(lockCtx, stateOne, lockInfoOne, m.Ui, m.Colorize())
		if err != nil {
			return fmt.Errorf("Error locking source state: %s", err)
		}
		defer clistate.Unlock(stateOne, lockIDOne, m.Ui, m.Colorize())

		lockInfoTwo := state.NewLockInfo()
		lockInfoTwo.Operation = "migration"
		lockInfoTwo.Info = "destination state"

		lockIDTwo, err := clistate.Lock(lockCtx, stateTwo, lockInfoTwo, m.Ui, m.Colorize())
		if err != nil {
			return fmt.Errorf("Error locking destination state: %s", err)
		}
		defer clistate.Unlock(stateTwo, lockIDTwo, m.Ui, m.Colorize())

		// We now own a lock, so double check that we have the version
		// corresponding to the lock.
		if err := stateOne.RefreshState(); err != nil {
			return fmt.Errorf(strings.TrimSpace(
				errMigrateSingleLoadDefault), opts.OneType, err)
		}
		if err := stateTwo.RefreshState(); err != nil {
			return fmt.Errorf(strings.TrimSpace(
				errMigrateSingleLoadDefault), opts.OneType, err)
		}

		one = stateOne.State()
		two = stateTwo.State()
	}

	// Clear the legacy remote state in both cases. If we're at the migration
	// step then this won't be used anymore.
	if one != nil {
		one.Remote = nil
	}
	if two != nil {
		two.Remote = nil
	}

	var confirmFunc func(state.State, state.State, *backendMigrateOpts) (bool, error)
	switch {
	// No migration necessary
	case one.Empty() && two.Empty():
		return nil

	// No migration necessary if we're inheriting state.
	case one.Empty() && !two.Empty():
		return nil

	// We have existing state moving into no state. Ask the user if
	// they'd like to do this.
	case !one.Empty() && two.Empty():
		confirmFunc = m.backendMigrateEmptyConfirm

	// Both states are non-empty, meaning we need to determine which
	// state should be used and update accordingly.
	case !one.Empty() && !two.Empty():
		confirmFunc = m.backendMigrateNonEmptyConfirm
	}

	if confirmFunc == nil {
		panic("confirmFunc must not be nil")
	}

	if !opts.force {
		// Abort if we can't ask for input.
		if !m.input {
			return errors.New("error asking for state migration action: input disabled")
		}

		// Confirm with the user whether we want to copy state over
		confirm, err := confirmFunc(stateOne, stateTwo, opts)
		if err != nil {
			return err
		}
		if !confirm {
			return nil
		}
	}

	// Confirmed! Write.
	if err := stateTwo.WriteState(one); err != nil {
		return fmt.Errorf(strings.TrimSpace(errBackendStateCopy),
			opts.OneType, opts.TwoType, err)
	}
	if err := stateTwo.PersistState(); err != nil {
		return fmt.Errorf(strings.TrimSpace(errBackendStateCopy),
			opts.OneType, opts.TwoType, err)
	}

	// And we're done.
	return nil
}

func (m *Meta) backendMigrateEmptyConfirm(one, two state.State, opts *backendMigrateOpts) (bool, error) {
	inputOpts := &terraform.InputOpts{
		Id: "backend-migrate-copy-to-empty",
		Query: fmt.Sprintf(
			"Do you want to copy state from %q to %q?",
			opts.OneType, opts.TwoType),
		Description: fmt.Sprintf(
			strings.TrimSpace(inputBackendMigrateEmpty),
			opts.OneType, opts.TwoType),
	}

	// Confirm with the user that the copy should occur
	for {
		v, err := m.UIInput().Input(inputOpts)
		if err != nil {
			return false, fmt.Errorf(
				"Error asking for state copy action: %s", err)
		}

		switch strings.ToLower(v) {
		case "no":
			return false, nil

		case "yes":
			return true, nil
		}
	}
}

func (m *Meta) backendMigrateNonEmptyConfirm(
	stateOne, stateTwo state.State, opts *backendMigrateOpts) (bool, error) {
	// We need to grab both states so we can write them to a file
	one := stateOne.State()
	two := stateTwo.State()

	// Save both to a temporary
	td, err := ioutil.TempDir("", "terraform")
	if err != nil {
		return false, fmt.Errorf("Error creating temporary directory: %s", err)
	}
	defer os.RemoveAll(td)

	// Helper to write the state
	saveHelper := func(n, path string, s *terraform.State) error {
		f, err := os.Create(path)
		if err != nil {
			return err
		}
		defer f.Close()

		return terraform.WriteState(s, f)
	}

	// Write the states
	onePath := filepath.Join(td, fmt.Sprintf("1-%s.tfstate", opts.OneType))
	twoPath := filepath.Join(td, fmt.Sprintf("2-%s.tfstate", opts.TwoType))
	if err := saveHelper(opts.OneType, onePath, one); err != nil {
		return false, fmt.Errorf("Error saving temporary state: %s", err)
	}
	if err := saveHelper(opts.TwoType, twoPath, two); err != nil {
		return false, fmt.Errorf("Error saving temporary state: %s", err)
	}

	// Ask for confirmation
	inputOpts := &terraform.InputOpts{
		Id: "backend-migrate-to-backend",
		Query: fmt.Sprintf(
			"Do you want to copy state from %q to %q?",
			opts.OneType, opts.TwoType),
		Description: fmt.Sprintf(
			strings.TrimSpace(inputBackendMigrateNonEmpty),
			opts.OneType, opts.TwoType, onePath, twoPath),
	}

	// Confirm with the user that the copy should occur
	for {
		v, err := m.UIInput().Input(inputOpts)
		if err != nil {
			return false, fmt.Errorf(
				"Error asking for state copy action: %s", err)
		}

		switch strings.ToLower(v) {
		case "no":
			return false, nil

		case "yes":
			return true, nil
		}
	}
}

type backendMigrateOpts struct {
	OneType, TwoType string
	One, Two         backend.Backend

	// Fields below are set internally when migrate is called

	oneEnv string // source env
	twoEnv string // dest env
	force  bool   // if true, won't ask for confirmation
}

const errMigrateLoadStates = `
Error inspecting state in %q: %s

Prior to changing backends, Terraform inspects the source and destination
states to determine what kind of migration steps need to be taken, if any.
Terraform failed to load the states. The data in both the source and the
destination remain unmodified. Please resolve the above error and try again.
`

const errMigrateSingleLoadDefault = `
Error loading state from %q: %s

Terraform failed to load the default state from %[1]q.
State migration cannot occur unless the state can be loaded. Backend
modification and state migration has been aborted. The state in both the
source and the destination remain unmodified. Please resolve the
above error and try again.
`

const errMigrateMulti = `
Error migrating the environment %q from %q to %q:

%s

Terraform copies environments in alphabetical order. Any environments
alphabetically earlier than this one have been copied. Any environments
later than this haven't been modified in the destination. No environments
in the source state have been modified.

Please resolve the error above and run the initialization command again.
This will attempt to copy (with permission) all environments again.
`

const errBackendStateCopy = `
Error copying state from %q to %q: %s

The state in %[1]q remains intact and unmodified. Please resolve the
error above and try again.
`

const inputBackendMigrateEmpty = `
Pre-existing state was found in %q while migrating to %q. No existing
state was found in %[2]q. Do you want to copy the state from %[1]q to
%[2]q? Enter "yes" to copy and "no" to start with an empty state.
`

const inputBackendMigrateNonEmpty = `
Pre-existing state was found in %q while migrating to %q. An existing
non-empty state exists in %[2]q. The two states have been saved to temporary
files that will be removed after responding to this query.

One (%[1]q): %[3]s
Two (%[2]q): %[4]s

Do you want to copy the state from %[1]q to %[2]q? Enter "yes" to copy
and "no" to start with the existing state in %[2]q.
`

const inputBackendMigrateMultiToSingle = `
The existing backend %[1]q supports environments and you currently are
using more than one. The target backend %[2]q doesn't support environments.
If you continue, Terraform will offer to copy your current environment
%[3]q to the default environment in the target. Your existing environments
in the source backend won't be modified. If you want to switch environments,
back them up, or cancel altogether, answer "no" and Terraform will abort.
`

const inputBackendMigrateMultiToMulti = `
Both the existing backend %[1]q and the target backend %[2]q support
environments. When migrating between backends, Terraform will copy all
environments (with the same names). THIS WILL OVERWRITE any conflicting
states in the destination.

Terraform initialization doesn't currently migrate only select environments.
If you want to migrate a select number of environments, you must manually
pull and push those states.

If you answer "yes", Terraform will migrate all states. If you answer
"no", Terraform will abort.
`
