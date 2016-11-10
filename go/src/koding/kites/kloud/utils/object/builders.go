package object

import "os"

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

// TabPrinter is used to print any slice of values
// encoded with a tabwriter.
var TabPrinter = &Printer{
	W: os.Stdout,
}

// JSONPrinter is used to print any slice of values
// encoded with JSON.
var JSONPrinter = &Printer{
	Tag:  "json",
	JSON: true,
	W:    os.Stdout,
}
