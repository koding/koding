/*
Package config parses files with format similar to INI files.
Comments starts with '#' or ';'.
Each line define a key and a value, both strings. Between them you can use  =, : or just spaces.

  foo: bar
  foo = bar
  foo bar

In the above example the key is 'key' and the value is 'value with spaces'.
You can also specify sections:

  [section_1]
  foo 1

  [section_2]
  foo 2

All top level options are grouped in a main section. The main section name is passed to the ParseFile function.

  sections, err := config.ParseFile("test.conf", mainSectionName)

ParseFile returns a map where keys are section names, and values are options.
Options are simple map with string for both keys and values.

Example file:

  # comment 1
  # comment 2

  url http://example.com

  [development]
  db.host     localhost
  db.username foo-dev
  db.password bar-dev

  [production]
  db.host     example.com
  db.username foo-production
  db.password bar-production

Usage example:

  package main

  import (
    "fmt"
    "github.com/pilu/config"
  )

  func main() {
    mainSectionName := "main"
    // Top level options are grouped in a section called "main"
    sections, err := config.ParseFile("test.conf", mainSectionName)
    if err != nil {
      panic(err)
    }

    for section, options := range sections {
      fmt.Printf("'%s': \n", section)
      for key, value := range options {
        fmt.Printf("  '%s' = '%s' \n", key, value)
      }
    }

  }
*/
package config
