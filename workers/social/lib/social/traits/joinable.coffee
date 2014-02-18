module.exports = class Joinable

  {secure} = require 'bongo'

  KodingError = require '../error'

  @fetchMyMemberships = secure (client, ids, as, callback)->
    [callback, as] = [as, callback] unless callback
    as ?= 'member'
    {delegate} = client.connection
    delegate.filterRelatedIds ids, as, callback

  addToGroup_ =(client, {as}, callback)->
    as ?= 'member'
    {delegate} = client.connection
    @addMember delegate, as, (err)=>
      if err then callback err
      else
        @emit 'MemberAdded', delegate  if as is 'member'
        @updateCounts()
        callback null
      # TODO: we used to do the below, but on second thought, it's not a very good idea:
      # else delegate.addGroup this, as, callback

  addToPrivateGroup_ =(client, {as, inviteCode}, callback)->
    {delegate} = client.connection
    JInvitation = require '../models/invitation'
    selector = {code: inviteCode, status: 'active', group: @title}
    JInvitation.one selector, (err, invite)=>
      if err then callback err
      else unless invite?
        callback new KodingError 'Invalid invitation code.'
      else
        addToGroup_.call this, (err)->
          if err then callback err
          else invite.redeem delegate, (err)-> callback err

  join: secure (client, options, callback)->
    {delegate} = client.connection
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    if @privacy is 'public'
      addToGroup_.call @, client, options, callback
    else if @privacy is 'private'
      addToPrivateGroup_.call @, client, options, callback

  removeFromGroup_ =(client, {as}, callback)->
    as ?= 'member'
    {delegate} = client.connection
    @removeMember delegate, as, callback
    @emit 'MemberRemoved', delegate  if as is 'member'
      # if err then callback err
      # else delegate.removeGroup this, as, callback

  leave: secure (client, options, callback)->
    {delegate} = client.connection
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    removeFromGroup_.call @, client, options, callback

