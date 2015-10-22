log = ->
  console.log '[handlers:memberremoved]', arguments...

module.exports = memberRemoved = ({ group, member, requester }) ->

  # Ignore kicks for guests and koding
  return  if group.slug in ['guests', 'koding']

  # Find the reason of removal
  reason = if member.getId().equals requester.getId() then 'leave' else 'kick'

  member.fetchUser (err, user) ->
    return log 'Failed to fetch user:', err  if err or not user

    userId = user.getId()

    JMachine = require '../machine'
    JMachine.some
      'provider'  : { $nin: ['koding', 'managed'] }
      'users.id'  : userId
      'groups.id' : group.getId()
    , {}
    , (err, machines = []) ->

      return log 'Failed to fetch machines:', err  if err

      machines.forEach (machine) ->

        owner = no # Make sure the user is owner of the machine
        for u in machine.users
          if u.owner and u.sudo and userId.equals u.id
            owner = yes
            break

        machine.removeUsers { targets: [ user ] }, (err) ->
          log "Couldn't remove user from users:", err  if err
          return  if not owner or reason is 'leave'

          requester.fetchUser (err, admin) ->
            return log 'Failed to fetch requester:', err  if err or not admin

            machine.addUsers { targets: [ admin ], asOwner: yes }, (err) ->
              return log 'Failed to change ownership:', err  if err
