KONFIG      = require 'koding-config-manager'
jraphical   = require 'jraphical'
shortid     = require('shortid')
Bongo       = require 'bongo'
Tracker     = require './tracker'
KodingError = require '../error'
{ extend }  = require 'underscore'
async       = require 'async'
_           = require 'lodash'
{ protocol, hostname } = KONFIG
{ secure, signature } = Bongo

emailsanitize = require './user/emailsanitize'

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/protected'


  { permit } = require './group/permissionset'

  @share()

  @set
    permissions     :
      'send invitations'  : ['member']
      'remove invitation' : ['member']
    indexes         :
      code          : 'unique'
      # email         : 'ascending'
      # groupName     : 'ascending'
      #
      # TODO(cihagir) create a compound unique index on groupName and email
    sharedMethods   :

      instance:
        remove:[
          (signature Function)
          (signature Object, Function)
        ]
        accept:[
          (signature Function)
          (signature Object, Function)
        ]
      static:
        some:[
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        search:[
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        create:
          (signature Object, Function)
        byCode:
          (signature String, Function)
        revokeInvitation:
          (signature Object, Function)
        sendInvitationByCode:[
          (signature String, Function)
          (signature Object, String, Function)
        ]

    sharedEvents    :
      static        : []
      instance      : []
    schema          :
      code          :
        type        : String
        required    : yes
      email         :
        type        : String
        required    : yes
        set         : emailsanitize
      hash          :
        type        : String
        required    : yes
      firstName     :
        type        : String
      lastName      :
        type        : String
      groupName     :
        type        : String
        required    : yes
      status        :
        type        : String
        enum        : ['invalid status type', [
          'pending',
          'accepted'
        ]]
        default     : 'pending'
      createdAt     :
        type        : Date
        default     : -> new Date
      modifiedAt    :
        type        : Date
        default     : -> new Date
      role          :
        type        : String
        default     : -> 'member'
      inviterId    :
        type        : String

  @revokeInvitation: permit 'remove invitation',
    success: (client, invite, callback) ->

      { connection: { delegate:account } } = client
      account.fetchMyPermissions client, (err, permissionAndRoles) ->

        return callback new KodingError 'Couldn\'t fetch user permissions'  if err

        { _id } = account
        { roles } = permissionAndRoles
        groupName = client.context.group

        return callback null, this  unless groupName

        hasPermisson = 'admin' in roles or 'owner' in roles
        { inviterId, email, groupName } = invite

        unless inviterId
          return callback new KodingError 'You don\'t have permission'

        if not hasPermisson and _id.toString() isnt inviterId
          return callback new KodingError 'You don\'t have permission'

        queue = [
          (next) ->
            JInvitation.remove { email, groupName }, next

          (next) ->
            data = { id: invite._id, type: 'remove' }
            notifyGroupOnInvitationChange groupName, data, next
        ]

        async.series queue, callback


  notifyGroupOnInvitationChange = (slug, data, callback) ->

    JGroup    = require './group'
    JGroup.one { slug }, (err, group) ->

      return callback err  if err or not group

      group.sendNotification 'InvitationChanged', data
      callback()


  accept$: permit 'send invitations',
    success: (client, callback) ->
      { delegate } = client.connection
      @accept delegate, callback

  accept: (account, callback) ->
    operation = { $set : { status: 'accepted', 'modifiedAt': new Date() } }
    @update operation, callback

  # validTypes holds states that can still redeemable
  validTypes: ['pending']

  isValid: -> @status in @validTypes

  # remove deletes an invitation from database
  remove$: permit 'remove invitation',
    success: (client, callback) ->
      @remove callback

  # some selects result set for invitations, it adds group name automatically
  @some$: permit 'send invitations',
    success: (client, selector, options, callback) ->

      { groupSlug }        = selector
      groupName            = client.context.group or 'koding'
      selector           or= {}
      selector.status    or= 'pending'
      selector.groupName   = groupName # override group name in any case
      fetchInvitations     = ->
        delete selector.groupSlug

        { limit }       = options
        options.sort  or= { createdAt : -1 }
        options.skip   ?= 0
        options.limit or= 25
        options.limit   = Math.min options.limit, 25 # admin can fetch max 25 record

        JInvitation.some selector, options, callback

      if groupSlug and client.context.group is 'koding'
        @canFetchInvitationsAsSuperAdmin client, (err, isSuperAdmin) ->
          selector.groupName = groupSlug  if isSuperAdmin
          fetchInvitations()
      else
        fetchInvitations()


  # search searches database with given query string, adds `starting
  # with regex` around query param
  @search$: permit 'send invitations',
    success: (client, selector, options, callback) ->
      return callback new KodingError 'query is not set'  if query is ''
      # get query from selector and delete it, we need modification for search
      # string
      { query } = selector
      $query = ///^#{query}///
      delete selector.query

      selector = extend selector, { $or : [
          { 'firstName' : $query }
          { 'email'     : $query }
        ]
      }

      JInvitation.some$ client, selector, options, callback

  # create creates JInvitation documents for all given invitations and
  # triggers sendInvitationEmail
  @create: permit 'send invitations',
    success: (client, options, callback) ->
      JGroup    = require './group'
      groupName = client.context.group or 'koding'

      JGroup.one { slug: groupName }, (err, group) =>
        return callback new KodingError err                   if err
        return callback new KodingError 'group doesnt exist'  if not group

        { invitations, forceInvite, returnCodes, noEmail } = options

        createInvites = (hasAdminRights = no) ->

          queue = invitations.map (invitationData) -> (end) ->
            invitationData.forceInvite = forceInvite
            invitationData.noEmail     = noEmail
            invitationData.groupName   = groupName
            invitationData.role        = 'member'  unless hasAdminRights

            createSingleInvite client, group, invitationData, end

          async.parallel queue, (err, codes) ->
            return callback err  if err

            unless returnCodes

              data = { type: 'new_invitations' }

              return notifyGroupOnInvitationChange groupName, data, callback

            return callback null, codes

        # check if requester tries to create an invite with admin role
        hasAdminInvite = no
        invitations.forEach (invitation) ->
          hasAdminInvite = yes  if invitation.role is 'admin'

        if hasAdminInvite
          # if so we need to make sure if requester has that role as well
          @canCreateAdminInvitations client, (err, hasAdminRights = no) ->
            # ignore err here since it will be AccessDenied if requester
            # does not have admin rights on this team context ~ GG
            createInvites hasAdminRights

        else
          createInvites hasAdminRights = no


  @canFetchInvitationsAsSuperAdmin: permit
    advanced: [ { permission: 'remove invitation', superadmin: yes } ]


  @canCreateAdminInvitations: permit
    advanced: [
      { permission: 'remove invitation' }
      { permission: 'remove invitation', superadmin: yes }
    ]


  createSingleInvite = (client, group, invitationData, end) ->
    { email, role, forceInvite, noEmail } = invitationData
    { _id } = client.connection.delegate

    invitationData.inviterId = _id

    groupName  = group.slug
    inviteInfo = null

    queue = [
      (fin) ->
        JInvitation.one { email, groupName }, fin

    , (invite, fin) ->
      [fin, invite] = paramSwapper invite, fin

      return fin null, no  unless invite
      return invite.remove fin  if forceInvite
      invite.alreadyInvited = yes
      inviteInfo = invite
      return fin null, yes

    , (alreadyInvited, fin) ->
      [fin, alreadyInvited] = paramSwapper alreadyInvited, fin

      return fin null, yes  if alreadyInvited
      isAlreadyMember group, email, fin

    , (alreadyMember, fin) ->
      [fin, alreadyMember] = paramSwapper alreadyMember, fin

      return fin null, no  if alreadyMember
      createInviteInstance invitationData, fin

    , (invite, fin) ->
      [fin, invite] = paramSwapper invite, fin
      inviteInfo = invite if invite

      return fin()  if noEmail or not invite
      JInvitation.sendInvitationEmail client, invite, fin

    ]

    async.waterfall queue, (err) ->
      return end new KodingError err  if err
      return end null, inviteInfo

  paramSwapper = (param, fin) ->
    # this is here bc of fucking cyclomatic complexity error of linter
    # if you put a few more `if` statements above it will cry
    # this should be better done inline - SY
    [fin, param] = [param, fin]  unless fin
    return [fin, param]

  createInviteInstance = (options, callback) ->

    { email, groupName, role, firstName, lastName, inviterId } = options

    JUser = require './user'
    hash  = JUser.getHash email

    # eg: VJPj9gUQ
    code = shortid.generate()
    data = { code, hash, email, groupName, role }

    # firstName and lastName are optional
    data.firstName = firstName  if firstName
    data.lastName  = lastName   if lastName
    data.inviterId = inviterId

    invite = new JInvitation data
    invite.save (err) ->
      return callback new KodingError err  if err
      return callback null, invite


  # isAlreadyMember checks if the given email
  # is already member of the given group
  isAlreadyMember = (group, email, callback) ->
    return callback new KodingError 'group is not set'  if not group
    return callback new KodingError 'email is not set'  if not email

    JUser = require './user'
    JUser.one { email }, (err, user) ->
      return callback new KodingError err   if err
      return callback null, no              if not user

      user.fetchOwnAccount (err, account) ->

        return callback new KodingError err  if err
        return callback null, no             if not account

        group.isMember account, callback


  # byCode fetches an invitation by its code
  @byCode: (code, callback) ->
    @one { code }, callback

  # sendInvitationByCode sends email according to data stored in
  # JInvitation selected by given code
  @sendInvitationByCode: permit 'send invitations',
    success: (client, code, callback) ->

      JInvitation.byCode code, (err, invitation) ->
        return callback err  if err

        JInvitation.sendInvitationEmail client, invitation, (err) ->
          return callback err  if err

          invitation.modifiedAt = new Date
          invitation.update callback

  # sendInvitationEmail sends email according to given JInvitation
  @sendInvitationEmail: (client, invitation, callback) ->

    { delegate }  = client.connection
    { profile }   = delegate

    inviter       = getName delegate
    groupLink     = "#{protocol}//#{invitation.groupName}.#{hostname}/"

    imgURL   = "#{protocol}//gravatar.com/avatar/#{profile.hash}?size=85&d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.140.png&r=g"

    if profile.avatar
      imgURL = "#{protocol}//#{hostname}/-/image/cache?endpoint=crop&grow=false&width=85&height=85&url=#{encodeURIComponent profile.avatar}"

    properties =
      groupName    : invitation.groupName
      inviter      : inviter
      inviterImage : imgURL
      link         : groupLink + "Invitation/#{encodeURIComponent invitation.code}"

    Tracker.identifyAndTrack invitation.email, { subject : Tracker.types.INVITED_TEAM }, properties, callback

  getName = (delegate) ->

    { nickname, firstName, lastName } = delegate.profile

    name = nickname
    name = firstName              if firstName
    name = "#{name} #{lastName}"  if firstName and lastName

    return name


  do ->

    JGroup = require './group'

    JGroup.on 'MemberRemoved', ({ member, group }) ->

      return  unless member or group
      return  if group.slug in ['guests', 'koding']

      member.fetchUser (err, user) ->
        return console.log 'Failed to fetch member:', err  if err or not user

        JInvitation.remove {
          email     : user.email
          groupName : group.slug
        }, (err) ->
          console.log 'Failed to remove existing invitations', err  if err
