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
      users           : Array
      groups          : Array
      isEnabled       :
        type          : Boolean
        default       : yes
      shouldDelete    :
        type          : Boolean
        default       : no

  do ->

    handleError = (err)-> console.error err  if err

    JGroup  = require './group'
    JUser   = require './user'

    addVm = ({ target, user, name, sudo, groups })->
      vm = new JVM {
        name: name
        users: [
          { id: user.getId(), sudo: yes }
        ]
        groups: groups ? []
      }
      vm.save (err)-> target.addVm vm, handleError

    wrapGroup =(group)-> [ { id: group.getId() } ]

    JGroup.on 'GroupCreated', ({group, creator})->
      creator.fetchUser (err, user)->
        if err then handleError err
        else
          addVm {
            user
            target  : group
            sudo    : yes
            name    : group.slug
            groups  : wrapGroup group
          }

    JGroup.on 'GroupDestroyed', ({group, member})->
      group.fetchVms (err, vms)->
        if err then handleError err
        else vms.forEach (vm)-> vm.remove handleError

    JGroup.on 'MemberAdded', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else if group.slug is 'koding'
          # TODO: this special case for koding should be generalized for any group.
          addVm {
            user
            target  : member
            sudo    : yes
            name    : member.profile.nickname
          }
        else
          member.checkPermission group, 'sudoer', (err, hasPermission)->
            if err then handleError err
            else
              group.fetchVms (err, vms)->
                if err then handleError err
                else vms.forEach (vm)->
                  vm.update {
                    $addToSet: users: { id: user.getId(), sudo: hasPermission }
                  }, handleError

    JGroup.on 'MemberRemoved', ({group, member})->
      member.fetchUser (err, user)->
        if err then handleError err
        else if group.slug is 'koding'
          member.fetchVms (err, vms)->
            if err then handleError err
            else vms.forEach (vm)->
              vm.update {
                $set: { isEnabled: no, shouldDelete: yes }
              }, handleError
        else
          # group.fetchVms (err, vms)->
          #   if err then handleError err
          #   else vms.forEach (vm)->
          #     JVM.update {_id: vm.getId()}, { $pull: id: user.getId() }, handleError
          # TODO: the below is more efficient and a little less strictly correct than the above:
          JVM.update { groups: group.getId() }, { $pull: id: user.getId() }, handleError

    JGroup.on 'MemberRolesChanged', ({group, member})->
      return  if group.slug 'koding'  # TODO: remove this special case
      member.fetchUser (err, user)->
        if err then handleError err
        else
          member.checkPermission group, 'sudoer', (err, hasPermission)->
            if err then handleError err
            else if hasPermission
              member.fetchVms (err, vms)->
                if err then handleError err
                else
                  vms.forEach (vm)->
                    vm.update {
                      $set: users: vm.users.map (userRecord)->
                        isMatch = userRecord.id.equals user.getId()
                        return userRecord  unless isMatch
                        return { id, sudo: hasPermission }
                    }, handleError
