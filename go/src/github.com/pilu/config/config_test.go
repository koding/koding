package config

import (
  "testing"
  "strings"
  "bufio"
  assert "github.com/pilu/miniassert"
)

func TestParse(t *testing.T) {
  content := `
  # comment 1
  ; comment 2

  foo 1
  bar 2

  [section_1]

  foo       3 # using spaces after the key
  bar				4 # using tabs after the key
  # other options for section_1 after section_2

  [section_2]
  a:1
  b: 2
  c : 3
  d :4
  e=5
  f= 6
  g = 7
  h =8

  url: http://example.com

  [section_3]

  [section_1] # redefine section_1 without removing previous options

  baz 5 6     # value is "5 6"
  qux 7
  quux # blank value


  `
  reader := bufio.NewReader(strings.NewReader(content))
  sections, _ := parse(reader, "main")

  assert.Equal(t, 4, len(sections))

  // Main section
  main_section := sections["main"]
  assert.Equal(t, 2, len(main_section))
  assert.Equal(t, "1", main_section["foo"])
  assert.Equal(t, "2", main_section["bar"])

  // Section 1
  section_1 := sections["section_1"]
  assert.Equal(t, 5, len(section_1))
  assert.Equal(t, "3", section_1["foo"])
  assert.Equal(t, "4", section_1["bar"])
  assert.Equal(t, "5 6", section_1["baz"])
  assert.Equal(t, "7", section_1["qux"])
  assert.Equal(t, "", section_1["quux"])

  // Section 2
  section_2 := sections["section_2"]
  assert.Equal(t, 9, len(section_2))
  assert.Equal(t, "1", section_2["a"])
  assert.Equal(t, "2", section_2["b"])
  assert.Equal(t, "3", section_2["c"])
  assert.Equal(t, "4", section_2["d"])
  assert.Equal(t, "5", section_2["e"])
  assert.Equal(t, "6", section_2["f"])
  assert.Equal(t, "7", section_2["g"])
  assert.Equal(t, "8", section_2["h"])
  assert.Equal(t, "http://example.com", section_2["url"])

  // Section 3
  section_3 := sections["section_3"]
  assert.Equal(t, 0, len(section_3))
}
