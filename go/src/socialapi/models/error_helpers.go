package models

import "github.com/lib/pq"

// IsUniqueConstraintError checks for the error if it is
//
// ```pq: duplicate key value violates unique constraint error```
//
func IsUniqueConstraintError(err error) bool {
	if err == nil {
		return false
	}

	pqError, ok := err.(*pq.Error)
	if !ok {
		return false
	}

	if pqError.Code.Name() != "unique_violation" {
		return false
	}

	return true
}
