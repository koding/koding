# DEPRECATED

Shadow catching is now part of `go tool vet`

```
go tool vet -shadow=true ./
```
Does what you want now. Make sure to run it separately from the standard `go vet` So you probably want:

```
go tool vet ./
go tool vet -shadow ./
```

In your relevant configuration.

Note that it does not ignore error types. But this is more strict anyway.

---

# go-nyet
More aggressive `go vet`

## Why?

I've been bitten by too many bugs caused by the shadowing of Go variables within subblocks. The time has come to end them once and for all.

## What does it do?

It checks for shadowed variables anywhere they appear in the code. Helpfully, it also type checks these variables and ignores anything of type `error`. This is because it's very common practice to shadow `err` and, well, shadowing `error` typed things hasn't hurt me nearly as much in the past.

It also checks for clobbering of variables that occur that aren't technically shadows. Eg:
```go
package main

import "os"

func main() {
    f, err := os.Open("")
    f, err = os.Open("")
    println(f, err)
}
```

Other aggressive checks may come in the future.

## How do I get it?

```
go get github.com/barakmich/go-nyet
```

And run

```bash
go-nyet ./...
# or
go-nyet subpackage
# or
go-nyet file.go
```

In the root of your project. If it complains about packages, you may need to `go install` them first.

Still working out the kinks, but give it a shot.

## License

BSD
