#
# This uses the test harness to install
# and configure cloud provisioner
#
# This can be removed once the installation
# of cloud provisioner is added to PE
#
# on every node, we need to install the fog gem
controller = nil
test_name "Install Puppet Cloud Provisioner"
# find the controller node
hosts.each do |host|
  if host['roles'].include? 'controller'
    controller = host
  end
end

skip_test 'test requires a master and controller' unless controller and master

step 'give the controller access to sign certs on the master'

cert_auth ="
path /certificate_status
method save
auth yes
allow #{controller.to_s}
"

# copy auth rules to the top of the file
auth_path='/etc/puppetlabs/puppet/auth.conf'

on master, "mv #{auth_path}{,.save}"
on master, "echo '#{cert_auth}' > #{auth_path};cat #{auth_path}.save >> #{auth_path}"

skip_test 'cannot find fog credentials' unless File.exists?(File.expand_path '~/.fog')

# install the latest version of fog, this should use the source version
# the vspere support will require master
step 'install latest version of fog'
on controller, 'yum install -y libxml2 libxml2-devel libxslt libxslt-devel'
on controller, '/opt/puppet/bin/gem install guid --no-rdoc --no-ri'
# the latest version of net-ssh causes fog to fail to install
on controller, '/opt/puppet/bin/gem install net-ssh -v 2.1.4 --no-ri --no-rdoc'
on controller, '/opt/puppet/bin/gem install fog --no-ri --no-rdoc'
on controller, 'cd /opt/puppet;git clone http://github.com/puppetlabs/puppetlabs-cloud-provisioner.git'
# assumes that you have bash installed
on controller, 'echo "export RUBYLIB=/opt/puppet/puppetlabs-cloud-provisioner/lib/:$RUBYLIB" >> /root/.bashrc'

step 'provide test machine ec2 credentials. Be warned, your credientials located at ~/.fog are being copied to the test machine at /root/.fog.'

scp_to controller, File.expand_path('~/.fog'), '/root/.fog'

step 'test that fog can connect to ec2 with provided credentials'
# this is failing b/c of net/ssh mismatch?
# sync clocks so that the EC2 connection will work
on controller, 'ntpdate pool.ntp.org'
on controller, '/opt/puppet/bin/ruby -rubygems -e \'require "fog"\' -e \'puts Fog::Compute.new(:provider => "AWS").servers.length >= 0\''
