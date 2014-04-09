Use like ```rerun github.com/skelterjohn/go.uik/uiktest```

Usage: ```rerun [--test] [--test-only] [--race] <import path> [arg]*```

For any go executable in a normal GOPATH workspace, rerun will watch its source,
rebuild, retest, and rerun. As long as ```go install <import path>``` works,
rerun will be able to find it.

Along with the target's source, rerun also watches the source of all
the target's non-GOROOT dependencies.
