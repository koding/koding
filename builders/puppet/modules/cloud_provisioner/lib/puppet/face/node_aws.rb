require 'puppet/face'

Puppet::Face.define(:node_aws, '0.0.1') do
  copyright "Puppet Labs", 2011
  license   "Apache 2 license; see COPYING"

  summary "View and manage Amazon AWS EC2 nodes."
  description <<-'EOT'
    This subcommand provides a command line interface to work with Amazon EC2
    machine instances.  The goal of these actions is to easily create new
    machines, install Puppet onto them, and tear them down when they're no longer
    required.
  EOT
end
