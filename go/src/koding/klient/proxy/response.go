package proxy

type Container struct {
    Hostname    string
}

type ContainersResponse struct {
    Containers []Container

    // TODO (acbodine): Add standard pagination fields here.
}
