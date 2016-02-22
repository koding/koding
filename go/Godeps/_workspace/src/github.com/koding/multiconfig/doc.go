// Package multiconfig provides a way to load and read configurations from
// multiple sources. You can read from TOML file, JSON file, Environment
// Variables and flag You can set the order of reader with MultiLoader. Package
// is extensible, you can add your custom Loader by implementing Load interface
package multiconfig
