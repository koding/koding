{ daisy } = require 'bongo'

log = ->
  console.log '[handlers:memberremoved]', arguments...


checkOwnership = (machine, user) ->

  userId = user.getId()
  owner  = no

  for u in machine.users
    if u.owner and u.sudo and userId.equals u.id
      owner = yes
      break

  return owner

setOwnerOfStack = (stack, newOwnerId, oldOwner) ->

  stack.unuseStackTemplate (err) ->
    log 'Failed to mark as unused stack:', err  if err
    stack.update {
      $set : {
        originId : newOwnerId
        title    : "#{stack.getAt 'title'} (@#{oldOwner})"
      }
    }, (err) ->
      log 'Failed to change ownership of stack:', err  if err


updateStacks = ({ reason, stacks, oldOwner, requesterId }) ->

  if reason is 'kick'
    stacks.forEach (stack) ->
      setOwnerOfStack stack, requesterId, oldOwner
  else
    stacks.forEach (stack) ->
      stack.delete (err) ->
        log 'Failed to delete stack:', err  if err


setOwnerOfMachine = (machine, { account, user, oldOwner }) ->

  # Update machine ownership to the admin who kicked the member
  machine.addUsers {
    targets: [ user ], asOwner: yes, sudo: yes
  }, (err) ->
    log 'Failed to change ownership of machine:', err  if err

    machine.update {
      $set: {
        'meta.oldOwner': oldOwner
      }
    }, (err) ->
      log 'Failed to set oldOwner of machine:', err  if err


  # Update workspace ownerships
  JWorkspace = require '../../workspace'
  JWorkspace.update
    machineUId    : machine.uid
  ,
    $set          :
      originId    : account.getId()
  ,
    multi         : yes
  , (err) ->
    log 'Failed to change ownership of workspace:', err  if err



updateMachineUsers = ({ machines, user, requester, reason }) ->

  return  unless reason is 'kick'

  machines.forEach (machine) ->
    # Check if the user is owner of the machine
    owner = checkOwnership machine, user

    machine.removeUsers { targets: [ user ] }, (err) ->
      log "Couldn't remove user from users:", err  if err

      # if not owner this machine we leave it to existing owner
      return  if not owner

      # otherwise we move the ownership of the machine to the requester
      requester.oldOwner = user.getAt 'username'
      setOwnerOfMachine machine, requester


module.exports = memberRemoved = ({ group, member, requester }) ->

  # Ignore kicks for guests and koding
  return  if group.slug in ['guests', 'koding']

  memberId       = member.getId()
  requesterId    = requester.getId()
  # Find the reason of removal
  reason         = if memberId.equals requesterId then 'leave' else 'kick'

  # Globals with-in queue
  memberJUser    = null
  requesterJUser = null
  memberMachines = []
  memberStacks   = []

  queue = [

    ->
      member.fetchUser (err, user) ->
        return log 'Failed to fetch member:', err  if err or not user
        memberJUser = user
        queue.next()

    ->
      if reason is 'leave'
        requesterJUser = memberJUser
        queue.next()
      else
        requester.fetchUser (err, user) ->
          if err or not user # even we fail to fetch JUser of admin somehow
                             # we don't need to cut the process here, we can
                             # continue with members info, and remove
                             # all the resources belongs to the user ~ GG
            log 'Failed to fetch requester:', err
            requesterJUser = memberJUser
          else
            requesterJUser = user
          queue.next()

    ->
      JMachine = require '../machine'
      JMachine.some
      # Not sure about this, open for debate, should we remove user from
      # managed vms and koding vms if somehow s/he has one in this group ~ GG
      # 'provider'  : { $nin: ['koding', 'managed'] }
        'users.id'  : memberJUser.getId()
        'groups.id' : group.getId()
      , {}
      , (err, machines = []) ->

        log 'Failed to fetch machines:', err  if err
        memberMachines = machines
        queue.next()

    ->
      updateMachineUsers {
        user      : memberJUser
        machines  : memberMachines
        requester :
          user    : requesterJUser
          account : requester
        reason
      }
      queue.next()

    ->
      JComputeStack = require '../../stack'
      JComputeStack.some
        originId : member.getId()
        group    : group.slug
      , {}
      , (err, stacks = []) ->

        log 'Failed to fetch stacks:', err  if err
        memberStacks = stacks
        queue.next()

    ->
      updateStacks {
        stacks   : memberStacks
        oldOwner : memberJUser.getAt 'username'
        requesterId, reason
      }
      queue.next()

  ]

  daisy queue
