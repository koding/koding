check [![Build Status](https://travis-ci.org/opennota/check.png?branch=master)](https://travis-ci.org/opennota/check)
=======

A set of utilities for checking Go sources.

## Installation

    $ go get github.com/opennota/check/cmd/defercheck
    $ go get github.com/opennota/check/cmd/structcheck
    $ go get github.com/opennota/check/cmd/varcheck

## Usage

Find repeating `defer`s.

```
$ defercheck go/parser
/usr/.../go/parser/parser.go:1929: Repeating defer p.closeScope() inside function parseSwitchStmt
```

Find unused struct fields.

```
$ structcheck --help
Usage of structcheck:
  -a=false: Count assignments only

$ structcheck fmt
/usr/.../fmt/print.go:110: pp.n
/usr/.../fmt/scan.go:173: ssave.nlIsEnd
/usr/.../fmt/scan.go:174: ssave.nlIsSpace
/usr/.../fmt/scan.go:175: ssave.argLimit
/usr/.../fmt/scan.go:176: ssave.limit
/usr/.../fmt/scan.go:177: ssave.maxWid
```

Find unused global variables and constants.

```
$ varcheck --help
Usage of varcheck:
  -e=false: Report exported variables and constants

$ varcheck image/jpeg
/usr/.../image/jpeg/writer.go:55: quantIndexChrominance
/usr/.../image/jpeg/writer.go:94: huffIndexChrominanceAC
/usr/.../image/jpeg/reader.go:53: maxH
/usr/.../image/jpeg/writer.go:92: huffIndexLuminanceAC
/usr/.../image/jpeg/writer.go:91: huffIndexLuminanceDC
/usr/.../image/jpeg/reader.go:54: maxV
/usr/.../image/jpeg/writer.go:93: huffIndexChrominanceDC
/usr/.../image/jpeg/writer.go:54: quantIndexLuminance
```

## Known limitations

structcheck doesn't handle embedded structs yet.

## License

GNU GPL v3+

