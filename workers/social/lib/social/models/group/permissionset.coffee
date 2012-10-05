{Model} = require 'bongo'
{Module} = require 'jraphical'

class JPermission extends Model
  @setSchema
    module  : String
    title   : String
    body    : String
    roles   : [String]

module.exports = class JPermissionSet extends Module

  @set
    schema        :
      permissions : [JPermission]

