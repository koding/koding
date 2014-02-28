package modelhelper

import (
	"strings"

	"github.com/chuckpreslar/inflect"
)

// GetCollectionName returns model name as collection name
// in mongo collection names are persisted as "<lowercase_first_letter>...<add (s)>
// e.g if name is Koding, in database it is "kodings"
func GetCollectionName(name string) string {
	// pluralize the name
	name = inflect.Pluralize(name)

	//split name into string array
	splittedName := strings.Split(name, "")

	//uppercase first character and assign back
	splittedName[0] = strings.ToLower(splittedName[0])

	//merge string array
	name = strings.Join(splittedName, "")
	return name

}
