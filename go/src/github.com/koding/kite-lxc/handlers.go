package lxc

import "github.com/koding/kite"

// Create is calling lxc-create with the given CreateParams information
func Create(r *kite.Request) (interface{}, error) {
	return lxcWrapper(create).ServeKite(r)
}

// Start is calling lxc-start with the given ContainerParams information
func Start(r *kite.Request) (interface{}, error) {
	return lxcWrapper(start).ServeKite(r)
}

// Stop is calling lxc-stop with the given ContainerParams information
func Stop(r *kite.Request) (interface{}, error) {
	return lxcWrapper(stop).ServeKite(r)
}

// Destroy is calling lxc-destroy with the given ContainerParams information
func Destroy(r *kite.Request) (interface{}, error) {
	return lxcWrapper(destroy).ServeKite(r)
}

// Info is calling lxc-info with the given ContainerParams information
func Info(r *kite.Request) (interface{}, error) {
	return lxcWrapper(info).ServeKite(r)
}
