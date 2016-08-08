neo4j.go
========

[![GoDoc](https://godoc.org/github.com/cihangir/neo4j?status.svg)](https://godoc.org/github.com/cihangir/neo4j)
[![Build Status](https://travis-ci.org/cihangir/neo4j.svg)](https://travis-ci.org/cihangir/neo4j)

Implementation of client package for communication with Neo4j Rest API.

For more information and documentation please read [Godoc Neo4j Page](http://godoc.org/github.com/cihangir/neo4j)


# setup

```
go get github.com/siesta/neo4j
```


# example usage


```
 Node:
     neo4jConnection := Connect("")
     node := &Node{}
     node.Id = "2229"
     err := neo4jConnection.Get(node)
     fmt.Println(node)

 Relationship:
    neo4jConnection := Connect("")
    rel             := &Relationship{}
    rel.Id          = "2412"
    neo4jConnection.Get(rel)

```
