{Model} = require 'bongo'

module.exports = class JVM extends Model

  @share()

  @trait __dirname, '../traits/protected'

  @set
    permissions       :
      'sudoer'        : []
    schema            :
      ip              :
        type          : String
        default       : -> null
      ldapPassword    :
        type          : String
        default       : -> null
      name            : String
      users           : [String]
      groups          : [String]

  do ->

    handleError = (require 'koding-bound').call console, 'error'

    JGroup  = require './group'
    JUser   = require './user'

    JUser.on 'UserCreated', (user)->
      console.warn 'User created hook needs to be implemented.'

    JUser.on 'UserDestroyed', (user)->
      console.warn 'User destroyed hook needs to be implemented.'

    JGroup.on 'GroupCreated', ({group, creator})->
      creator.fetchUser (err, user)->
        if err then handleError err
        else
          (new JVM {
            name: group.slug
            users: [
              { id: user.getId(), sudo: yes }
            ]
            groups: [
              { id: group.getId() }
            ]
          }).save handleError

    JGroup.on 'GroupDestroyed', ({group, member})->
      JVM.remove { name: group.slug }, handleError

    JGroup.on 'MemberAdded', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else
          JVM.update { name: group.slug }, {
            $addToSet:
              users:
                id      : user.getId()
                sudo    : no
          }, handleError

    JGroup.on 'MemberRemoved', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else
          JVM.update { name: group.slug }, { $pull: user.getId() }, handleError

    JGroup.on 'MemberRolesChanged', ({group, member})->
      member.checkPermission group, 'sudoer', (err, hasPermission)->
        if err then handleError err
        else
