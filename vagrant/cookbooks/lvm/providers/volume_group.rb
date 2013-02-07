def initialize *args
    super
    require 'lvm'
end

action :create do
    physical_volume_list = [new_resource.physical_volumes].flatten

    physical_volume_list.flatten.each do |pv|
        #make sure any pvs are not being used as filesystems (e.g. ephemeral0 on
        #AWS is always mounted at /mnt as an ext3 fs).
        if ::File.exist? pv
            mount pv do
                device pv
                action [ :umount, :disable ]
            end
        end
    end

    ruby_block "logical_volumes_updated_for_group_#{new_resource.name}" do
        block do
            new_resource.updated_by_last_action true
        end
        action :nothing
    end
    
    ruby_block "create_logical_volumes_for_group_#{new_resource.name}" do
        block do 
            new_resource.logical_volumes.each do |lv|
                lv.group new_resource.name
                lv.run_action :create
                lv.notifies :create, "ruby_block[logical_volumes_updated_for_group_#{new_resource.name}]"
            end
        end
        action :nothing
    end

    ruby_block "create_volume_group_#{new_resource.name}" do
        block do
            lvm = LVM::LVM.new

            name = new_resource.name
            physical_volumes = physical_volume_list.join ' '
            physical_extent_size = new_resource.physical_extent_size ? "-s #{new_resource.physical_extent_size}" : ''
            command = "vgcreate #{name} #{physical_extent_size} #{physical_volumes}"
            
            Chef::Log.debug "Executing lvm command '#{command}'"
            output = lvm.raw command
            Chef::Log.debug "Command output: '#{output}'"
            new_resource.updated_by_last_action true
        end
        not_if do 
            lvm = LVM::LVM.new
            lvm.volume_groups[new_resource.name] 
        end
        notifies :create, "ruby_block[create_logical_volumes_for_group_#{new_resource.name}]", :immediately
    end
end
