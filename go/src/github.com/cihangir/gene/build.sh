#! /bin/bash
set -o errexit

geneservices=(
  github.com/cihangir/gene/cmd/gene
  github.com/cihangir/geneddl/cmd/gene-ddl
  github.com/cihangir/gene/plugins/gene-models
  github.com/cihangir/gene/plugins/gene-rows
  github.com/cihangir/gene/plugins/gene-errors
  github.com/cihangir/gene/plugins/gene-kit
  github.com/cihangir/gene/plugins/gene-dockerfiles
  github.com/cihangir/gene/plugins/gene-tests
  github.com/cihangir/gene/plugins/gene-tests-funcs
  github.com/cihangir/gene/plugins/gene-js
  github.com/cihangir/gene/plugins/gene-jsbase
)

`which go` install -v "${geneservices[@]}"
