package object

// HCLBuilder provides custom encoding/decoding for values
// that have "hcl" tag.
var HCLBuilder = &Builder{
	Tag:       "hcl",
	Sep:       "_",
	Recursive: true,
}
