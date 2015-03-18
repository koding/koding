{Module} = require 'jraphical'

module.exports = class JGroupRole extends Module

  {dash}        = require 'bongo'
  KodingError   = require '../../error'

  @set
    softDelete        : yes
    schema            :
      title           : String
      value           : String
      isConfigureable :
        type          : String
        default       : no
      isDefault       :
        type          : Boolean
        default       : no

  @defaultRoles = [
    { title : "owner",      isDefault : yes }
    { title : "admin",      isDefault : yes }
    { title : "moderator",  isDefault : yes,  isConfigureable: yes }
    { title : "member",     isDefault : yes }
    { title : "guest",      isDefault : yes }
  ]

  @create = (formData, callback)->
    JGroup = require '../group'

    JGroupRole.one
      title : formData.title
    , (err, role)=>
      if err
        console.log err
        callback err
      else unless role
        newRole = new @ formData
        newRole.save (err)->
          if err then callback err
          else callback null, newRole
      else
        callback null, role

  createDefaultRolesHelper = (callback)->

    queue = JGroupRole.defaultRoles.map (roleData)->
      ->
        JGroupRole.create roleData, queue.fin.bind queue

    dash queue, callback

  @createDefaultRoles = (callback)->

    @count isDefault : yes, (err, count)=>

      unless count is @defaultRoles.length
        createDefaultRolesHelper callback
      else
        callback new KodingError "Default group roles are already created."



