package proxy

import (
    "bytes"
)

type ListRequest struct {
    Pod     string
}

type ExecRequest struct {
    Args    []string
    In      *bytes.Buffer
    Out     *bytes.Buffer
    Err     *bytes.Buffer
}
