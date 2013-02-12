Description
===========

Installs lvm2 package and ensures it stays upgraded.

Requirements
============

* Debian/Ubuntu
* RHEL/CentOS

Resources/Providers
===================

There are three LWRPs in the LVM cookbook that can be used to perform operations
with the Logical Volume Manager.

`lvm_physical_volume`
---------------------

Manages LVM physical volumes.

### Actions

- `:create` - Creates a new physical volume. Default.

### Attribute Parameters

- `name`
  The device to create the new physical volume on. Required, name parameter.

### Example

    lvm_physical_volume '/dev/sda'

`lvm_logical_volume`
--------------------

Manages LVM logical volumes

### Actions

- `:create` - Creates a new logical volume

### Attribute Parameters

- `name` - The name of the logical volume. Required, name parameter.
- `group` - The volume group in which to create the new volume. Required unless
  the volume is declared inside of an `lvm_volume_group` block (<a
  href='#volume_group'>see below</a>).
- `size` - The size of the volume. This can be any of the size specifications
  supported by LVM&mdash;SI bytes (e.g. 10G), physical extents, or percentages
  of all the extents in the volume group, all the free extents, or of the
  physical volumes assigned to the volume.
- `filesystem` - The filesystem to format the volume as. The appropriate tools
  must be installed for the filesystem.
- `mount_point` - Either a string containing the path to the mount point, or a
  Hash containing the following keys:
  - `location` - the directory to mount the volume on. Required.
  - `options` - the mount options for the volume.
  - `dump` - the `dump` field for the fstab entry.
  - `pass` - the `pass` field for the fstab entry.
- `physical_volumes` - An array of physical volumes that the volume will be
  restricted to.
- `stripes` - the number of stripes for the volume.
- `stripe_size` - the number of kilobytes per stripe segment. Must be a power of
  2 less than or equal to the physical extent size for the volume group.
- `mirrors` - the number of mirrors for the volume.
- `contiguous` - whether or not volume should use the contiguous allocation
  policy. Default is non-contiguous.
- `readahead` - the readahead sector count for the volume. Can be a value
  between 2 and 120, 'auto', or 'none'

### Example

    lvm_logical_volume 'home' do
        group 'vg00'
        size '25%VG'
        filesystem 'ext4'
        mount_point '/home'
        stripes 3
        mirrors 2
    end

<a name='volume_group' />
`lvm_volume_group`
------------------

Manages LVM volume groups.

### Actions

- `:create` - Creates a new volume group. Default.

### Attribute Parameters

- `name` - The name of the volume group. Required, name parameter.
- `physical_volumes` - A device or list of devices to use as physical volumes. If they
  haven't already been initialized as physical volumes, they will be
  initialized automatically. Required.
- `physical_extent_size` - The physical extent size for the volume group.
- `logical_volume` - A shortcut for creating a new `lvm_logical_volume`
  definition. The logical volumes will be created in the order they are
  declared.

### Example

    lvm_volume_group 'vg00' do
        physical_volumes [ /dev/sda, /dev/sdb, /dev/sdc ]
        logical_volume 'logs' do
            size '1G'
            filesystem 'xfs'
            mount_point :location => '/var/log', :options => 'noatime,nodiratime'
            stripes 3
        end
        logical_volume 'home' do
            size '25%VG'
            filesystem 'ext4'
            mount_point '/home'
            stripes 3
            mirrors 2
        end
    end

Usage
=====

Make sure the lvm package is always up to date with this recipe. Put
it in a base role that gets applied to all nodes.

License and Author
==================

Author:: Joshua Timberman <joshua@opscode.com>
Author:: Greg Symons <gsymons@drillinginfo.com>

Copyright:: 2011, Opscode, Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
