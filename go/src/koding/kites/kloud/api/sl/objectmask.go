package sl

import "koding/kites/kloud/utils/object"

var objectMask = &object.Builder{
	Tag:       "json",
	Sep:       ".",
	Recursive: true,
}

// ObjectMask builds object mask value, which is used in Softlayer API for
// requesting extra fields which are not being populated on request.
//
// ObjectMask assumes each field we want to read from Softlayer API has
// API name set in its json tag.
func ObjectMask(v interface{}, ignored ...string) []string {
	return objectMask.Build(v, ignored...).Keys()
}
