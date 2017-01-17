module.exports = class Joinable

  { secure } = require 'bongo'

  KodingError = require '../error'

  @fetchMyMemberships = secure (client, ids, as, callback) ->
    [callback, as] = [as, callback] unless callback
    as ?= 'member'
    { delegate } = client.connection
    delegate.filterRelatedIds ids, as, callback

  addToGroup_ = (client, { as }, callback) ->

    { delegate } = client.connection
    as         or= 'member'

    @addMember delegate, as, (err) =>
      if err then callback err
      else
        @emit 'MemberAdded', delegate  if as is 'member'
        callback null

  addToPrivateGroup_ = (client, { as, inviteCode }, callback) ->
    { delegate } = client.connection
    JInvitation  = require '../models/invitation'
    selector     = {
      code      : inviteCode
      groupName : @slug
    }

    JInvitation.one selector, (err, invite) =>

      if err then callback err
      else unless invite?
        callback new KodingError 'Invalid invitation code.'
      else
        addToGroup_.call this, client, { as }, (err) ->
          if err then callback err
          else invite.accept delegate, (err) -> callback err

  join: secure (client, options, callback) ->
    { delegate } = client.connection
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    if @privacy is 'public'
      addToGroup_.call this, client, options, callback
    else if @privacy is 'private'
      addToPrivateGroup_.call this, client, options, callback

  removeFromGroup_ = (client, { as }, callback) ->
    as ?= 'member'
    { delegate } = client.connection
    @removeMember delegate, as, callback
    @emit 'MemberRemoved', delegate  if as is 'member'
      # if err then callback err
      # else delegate.removeGroup this, as, callback

  leave: secure (client, options, callback) ->
    { delegate } = client.connection
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    removeFromGroup_.call this, client, options, callback
