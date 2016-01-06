{ dash } = require 'bongo'

error = (err) ->
  console.error err
  if err.errors?
    console.error lilErr  for lilErr in err.errors


initKodingGroup2 = (groupData, admins) ->
  JGroup = require './models/group'
  [owner, admins...] = admins
  JGroup.create null, groupData, owner, (err, { group }) ->
    console.error err  if err

    continuation = -> console.log 'group is created and initialized'

    fin = dash continuation, admins.map (admin) -> ->
      group.addAdmin admin, -> group.addMember admin, fin

initKodingGroup = ->
  console.log 'Initializing the Koding group'

  JUser         = require './models/user'
  JInvitation   = require './models/invitation'
  kodingAdmins  = require './kodingadmins'

  groupData     =
    title       : 'Koding'
    slug        : 'koding'
    body        : 'Say goodbye to your localhost'
    privacy     : 'public'
    visibility  : 'visible'
    counts      : { members: kodingAdmins.length }

  adminAccounts = []

  continuation = ->
    initKodingGroup2 groupData, adminAccounts

  fin = dash continuation, kodingAdmins.map (userData) -> ->

    JUser.createUser userData, (err, user, account) ->
      error err  if err
      adminAccounts.push account
      fin()

exports.init = (koding) ->
  console.warn 'Initialization code is temporarily disabled.'

