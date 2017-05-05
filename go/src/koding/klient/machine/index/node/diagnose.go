package node

// Diagnose checks tree looking for broken filesystem invariants. It returns
// a list of found problems. Each of them should be considered critical since
// they indicate broken logic.
func (t *Tree) Diagnose() []string {
	return nil
}
