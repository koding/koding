package proxy

import (
    "github.com/koding/kite"
)

type Proxy interface {

    // fs.*
    // FsReadDirectory(*kite.Request) (interface{}, error)
    // FsGlob(*kite.Request) (interface{}, error)
    ReadFile(*kite.Request) (interface{}, error)
    // FsWriteFile(*kite.Request) (interface{}, error)
    // FsUniquePath(*kite.Request) (interface{}, error)
    // FsGetInfo(*kite.Request) (interface{}, error)
    // FsSetPermissions(*kite.Request) (interface{}, error)
    // FsRemove(*kite.Request) (interface{}, error)
    // FsRename(*kite.Request) (interface{}, error)
    // FsCreateDirectory(*kite.Request) (interface{}, error)
    // FsMove(*kite.Request) (interface{}, error)
    // FsCopy(*kite.Request) (interface{}, error)

    // terminal.*
    // WebtermGetSessions(*kite.Request) (interface{}, error)
    // WebtermConnect(*kite.Request) (interface{}, error)
    // WebtermKillSession(*kite.Request) (interface{}, error)
    // WebtermKillSessions(*kite.Request) (interface{}, error)
    // WebtermRename(*kite.Request) (interface{}, error)

    // storage.*
    // StorageGet(*kite.Request) (interface{}, error)
    // StorageSet(*kite.Request) (interface{}, error)
    // StorageDelete(*kite.Request) (interface{}, error)

}

func MakeProxy() Proxy {
    return &LocalProxy{}
}
