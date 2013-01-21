group "koding" do
    gid 200
end


user "koding" do
    uid 200
    gid "koding"
    comment "Koding system user"
    shell "/bin/bash"
    home "/opt/koding"
end
