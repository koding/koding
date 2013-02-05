directory node['mongodb']['dbpath']
directory node['mongodb']['logpath']


lvm_volume_group 'vg0' do
    physical_volumes [ "/dev/xvdf", "/dev/xvdg" ]
    logical_volume 'fs_mongo_data' do
        size '50G'
        filesystem 'ext4'
        mount_point :location => node['mongodb']['dbpath'], :options => 'noatime,nodiratime'
        stripes 2
    end
end

lvm_volume_group 'vg1' do
    physical_volumes [ "/dev/xvdh" ]
    logical_volume 'fs_mongo_log' do
        size '100%'
        filesystem 'ext4'
        mount_point :location => node['mongodb']['logpath'], :options => 'noatime,nodiratime'
    end
end
