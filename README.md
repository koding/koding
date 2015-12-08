
# kd mount everything


## Vendoring

klientctl uses a combination of the Go 1.5 Vendoring Experiment and the
[GoVendor](https://github.com/kardianos/govendor) tool. You will likely
want both of these. Please refer to the respective documentation(s) as
needed, but for convenience we've compiled some quick-start instructions:

### Installing

After installing Go 1.5, the `GO15VENDOREXPERIMENT` environment variable
needs to be set to the value of `1`. This environment variable tells Go
to import packages from the vendor directory first. This can be done in
your Shell RC _(`.bashrc`, `.config/fish/config.fish`, etc)_. Example:

Bash:

```bash
export GO15VENDOREXPERIMENT=1
```

Fish:

```fish
set -Ux GO15VENDOREXPERIMENT 1
```

Go 1.5 handles the importing of vendored packages, but we use the tool
GoVendor to handle adding packages to that directory, and pinning them to
the specified versions. This can be installed simply with:

```bash
go get github.com/kardianos/govendor
```

### Adding to Vendor

To add a new package to the vendor directly, first make sure the package
is in your $GOPATH, then simply run:

```
govendor add github.com/some/dependency
```

### Updating a Vendor

If you need to update the vendored version of a library, follow the
following steps:

1. `go get -u github.com/some/dependency`
2. `govendor update github.com/some/dependency`

If you need to choose a specific commit manually, checkout that commit
beforehand. Example:

1. `cd $GOPATH/github.com/some/dependency`
2. `git checkout <commit>`
3. `cd $GOPATH/github.com/your/repo`
4. `govendor update github.com/some/dependency`
