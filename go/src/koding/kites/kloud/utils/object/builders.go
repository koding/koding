package object

// HCLBuilder provides custom encoding/decoding for values
// that have "hcl" tag.
var HCLBuilder = &Builder{
	Tag:       "hcl",
	Sep:       "_",
	Recursive: true,
}

// MetaBuilder provides custom encoding/decoding for
// jMachine.meta document.
var MetaBuilder = &Builder{
	Tag:       "bson",
	Sep:       ".",
	Prefix:    "meta",
	Recursive: true,
}
