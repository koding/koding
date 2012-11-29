# variables that need to be set at a higher level
ami='ami-06ad526f'
login='ubuntu'
keypair=@options[:keypair]
keyfile=@options[:keyfile]

# this method can be used to parse out the nodes
# that are described in STDOUT from the list
# action
def parse_node_list(stdout)
  node_status = {}
  entries = stdout.split("\ni")
  entries.each do |entry|
    status = {}
    # the first i did not get split out
    unless entry =~ /^i/
      entry='i'+entry
    end
    status_lines = entry.split("\n")
    # git rid of the first line
    # I don't care about the ids
    status_lines.shift
    status_lines.each do |status_line|
      status_line.gsub!(/^  /, '')
      attr = status_line.split(': ')
      if attr.size == 2
        status[attr[0]] = attr[1]
      end
    end
    # hash all of the properties by the dns_name of the node
    # I only care about entries that have a listed dnsname
    # the dns_names are deallocated when the machine shuts
    # down
    if status['dns_name']
      node_status[status['dns_name']] = status
    end
  end
  node_status
end

controller = nil
test_name "Test Puppet Cloud Provisioner: create, install, list and destroy"

# find the controller node
hosts.each do |host|
  if host['roles'].include? 'controller'
    controller = host
  end
end

step 'test that we can create ec2 instance(s)'

agent_dnsname=nil
on controller, "puppet node_aws create -i #{ami} --keypair #{keypair} --type t1.micro" do
  # set the dnsname as the last line returned
  agent_dnsname=stdout.split("\n").last
end

step "test that we can list the created instances: #{agent_dnsname}"

nodes_info=nil
on controller, 'puppet node_aws list' do
  nodes_info=parse_node_list(stdout)
  assert_equal('running', nodes_info[agent_dnsname]['state'], "Failed to launch an agent EC2 instance")
end

# copy the ec2 private key to the controller
# I would rather use ssh forwarding if I can
scp_to controller, File.expand_path(keyfile), "/root/.ssh/#{File.basename(keyfile)}"

step "test that we can install PE agent on #{agent_dnsname}"
agent_certname=nil
# I would like to be able to see stdout/err even when it fails?
on controller, "puppet node install --keyfile /root/.ssh/#{File.basename(keyfile)} --login #{login} --install-script=gems --server #{master} --debug --verbose --trace #{agent_dnsname}", :acceptable_exit_codes => [ 0 ] do
  agent_certname = stdout.split("\n").last.chomp
end

on controller, "puppet certificate sign #{agent_certname} --ca-location remote --mode agent" do
end

step "test that we can destroy the created instances: #{agent_dnsname}"

on controller, "puppet node_aws terminate #{agent_dnsname}" do
  last_line = stdout.split("\n").last
  assert_match(/Destroying #{nodes_info[agent_dnsname]['id']} \(#{agent_dnsname}\) ... Done/, last_line, 'Failed to destroy instance')
end

# instead of puppet node list, maybe I should use fog to double check?
on controller, 'puppet node_aws list' do
  nodes_list = parse_node_list(stdout)
  if my_node = nodes_list[agent_dnsname]
    assert(my_node['state'] == 'shutting-down' || my_node['state'] == 'terminated', "Node: #{agent_dnsname} was not shut down")
  end
  # I would like to fail if there are any extra instances?
  # but I cant if I share the key
  nodes_list.each do |name, my_node|
    unless my_node['state'] == 'shutting-down' || my_node['state'] == 'terminated'
      puts "Warning: node #{name} is not shut down"
    end
    # fail if any instances are running
  end
end
