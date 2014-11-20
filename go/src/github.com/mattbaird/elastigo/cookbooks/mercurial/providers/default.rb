action :sync do
  execute "sync repository #{new_resource.path}" do    
    not_if "hg identify #{new_resource.path}"
    command "hg clone -e 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' #{new_resource.repository} #{new_resource.path}"
  end
  execute "pull changes #{new_resource.path}" do
      command "cd #{new_resource.path} && hg pull -e 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' #{new_resource.repository}"
  end
  execute "update #{new_resource.path}" do
      command "cd #{new_resource.path} && hg update -r #{new_resource.reference}"
  end
  execute "sync update owner #{new_resource.path}" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
  end
  execute "sync update permissions #{new_resource.path}" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
  end
end
 
action :clone do
  execute "clone repository #{new_resource.path}" do
    not_if "hg identify #{new_resource.path}"
    command "hg clone -e 'ssh -i #{new_resource.key} -o StrictHostKeyChecking=no' #{new_resource.repository} #{new_resource.path}"
  end
  if new_resource.reference
      command "cd #{new_resource.path} && hg update -r #{new_resource.reference}"
  end
  execute "update owner #{new_resource.path}" do
    command "chown -R #{new_resource.owner}:#{new_resource.group} #{new_resource.path}"
  end
  execute "update permissions #{new_resource.path}" do
    command "chmod -R #{new_resource.mode} #{new_resource.path}"
  end
end
