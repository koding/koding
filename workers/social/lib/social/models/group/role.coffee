{Module} = require 'jraphical'

module.exports = class JGroupRole extends Module

  {daisy}       = require 'bongo'
  {KodingError} = require '../error'

  @trait __dirname, '../traits/protected'

  @set
    schema          :
      title         : String
      value         : String
      exclusive     :
        type        : Boolean
        default     : no

  @create = (formData, callback)->
    JGroup = require './group'

    JGroupRole.one
      title : options.title
    , (err, role)->
      if err
        console.log err
        callback err
      else unless role
        newRole = new @ formData
        newRole.save (err)->
          if err then callback err
          else callback null, newRole
      else
        callback null


do ->

  defaultRoles = [
    { title : "Admin",  value : "admin"}
    { title : "Member", value : "member"}
    { title : "Guest",  value : "guest"}
  ]

  defaultRoles.forEach (roleData)-> JGroupRole.create roleData

