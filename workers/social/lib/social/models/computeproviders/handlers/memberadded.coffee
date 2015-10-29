module.exports = memberAdded = ({ group, member }) ->

  # No need to try creating group stacks for guests or koding group members
  return  if group.slug in ['guests', 'koding']

  client =
    connection :
      delegate : member
    context    : { group : group.slug }

  ComputeProvider = require '../computeprovider'

  ComputeProvider.createGroupStack client,
    addGroupAdminToMachines: no # Marked this as no until
                                # we find a better solution ~ GG
  , (err, res = {}) ->

    { stack, results } = res

    if err?
      { nickname } = member.profile
      console.log "Create group #{group.slug} stack failed for #{nickname}:", err, results
