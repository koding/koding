{Module} = require 'jraphical'

module.exports = class JEnvironment extends Module

  @set
    indexes :
      name  : 'unique'
    schema  :
      name  : String
      vms   : [String] # IP addresses of the VM
      data  : Object