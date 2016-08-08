package scheduler

import "github.com/docker/swarmkit/api"

// Filter checks whether the given task can run on the given node.
// A filter may only operate
type Filter interface {
	// SetTask returns true when the filter is enabled for a given task
	// and assigns the task to the filter. It returns false if the filter
	// isn't applicable to this task.  For instance, a constraints filter
	// would return `false` if the task doesn't contain any constraints.
	SetTask(*api.Task) bool

	// Check returns true if the task assigned by SetTask can be scheduled
	// into the given node. This function should not be called if SetTask
	// returned false.
	Check(*NodeInfo) bool
}

// ReadyFilter checks that the node is ready to schedule tasks.
type ReadyFilter struct {
}

// SetTask returns true when the filter is enabled for a given task.
func (f *ReadyFilter) SetTask(_ *api.Task) bool {
	return true
}

// Check returns true if the task can be scheduled into the given node.
func (f *ReadyFilter) Check(n *NodeInfo) bool {
	return n.Status.State == api.NodeStatus_READY &&
		n.Spec.Availability == api.NodeAvailabilityActive
}

// ResourceFilter checks that the node has enough resources available to run
// the task.
type ResourceFilter struct {
	reservations *api.Resources
}

// SetTask returns true when the filter is enabled for a given task.
func (f *ResourceFilter) SetTask(t *api.Task) bool {
	r := t.Spec.Resources
	if r == nil || r.Reservations == nil {
		return false
	}
	if r.Reservations.NanoCPUs == 0 && r.Reservations.MemoryBytes == 0 {
		return false
	}
	f.reservations = r.Reservations
	return true
}

// Check returns true if the task can be scheduled into the given node.
func (f *ResourceFilter) Check(n *NodeInfo) bool {
	if f.reservations.NanoCPUs > n.AvailableResources.NanoCPUs {
		return false
	}

	if f.reservations.MemoryBytes > n.AvailableResources.MemoryBytes {
		return false
	}

	return true
}

// PluginFilter checks that the node has a specific volume plugin installed
type PluginFilter struct {
	t *api.Task
}

// SetTask returns true when the filter is enabled for a given task.
func (f *PluginFilter) SetTask(t *api.Task) bool {
	c := t.Spec.GetContainer()

	var volumeTemplates bool
	if c != nil {
		for _, mount := range c.Mounts {
			if mount.Type == api.MountTypeVolume &&
				mount.VolumeOptions != nil &&
				mount.VolumeOptions.DriverConfig != nil &&
				mount.VolumeOptions.DriverConfig.Name != "" &&
				mount.VolumeOptions.DriverConfig.Name != "local" {
				volumeTemplates = true
			}
		}
	}

	if (c != nil && volumeTemplates) || len(t.Networks) > 0 {
		f.t = t
		return true
	}

	return false
}

// Check returns true if the task can be scheduled into the given node.
// TODO(amitshukla): investigate storing Plugins as a map so it can be easily probed
func (f *PluginFilter) Check(n *NodeInfo) bool {
	// Get list of plugins on the node
	nodePlugins := n.Description.Engine.Plugins

	// Check if all volume plugins required by task are installed on node
	container := f.t.Spec.GetContainer()
	if container != nil {
		for _, mount := range container.Mounts {
			if mount.VolumeOptions != nil && mount.VolumeOptions.DriverConfig != nil {
				if !f.pluginExistsOnNode("Volume", mount.VolumeOptions.DriverConfig.Name, nodePlugins) {
					return false
				}
			}
		}
	}

	// Check if all network plugins required by task are installed on node
	for _, tn := range f.t.Networks {
		if !f.pluginExistsOnNode("Network", tn.Network.DriverState.Name, nodePlugins) {
			return false
		}
	}
	return true
}

func (f *PluginFilter) pluginExistsOnNode(pluginType string, pluginName string, nodePlugins []api.PluginDescription) bool {
	for _, np := range nodePlugins {
		if pluginType == np.Type && pluginName == np.Name {
			return true
		}
	}
	return false
}
