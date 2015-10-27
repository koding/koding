{ argv }    = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
jraphical   = require 'jraphical'
shortid     = require('shortid')
Bongo       = require 'bongo'
Tracker     = require './tracker'
KodingError = require '../error'
{ extend }  = require 'underscore'

{ protocol, hostname } = KONFIG
{ secure, signature, dash } = Bongo

emailsanitize = require './user/emailsanitize'

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/protected'


  { permit } = require './group/permissionset'

  @share()

  @set
    permissions     :
      'send invitations' : ['moderator', 'admin']
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

  accept$: secure (client, callback) ->
    { delegate } = client.connection
    @accept delegate, callback

  accept: (account, callback) ->
    operation = { $set : { status: 'accepted' } }
    @update operation, callback

  # validTypes holds states that can still redeemable
  validTypes: ['pending']

  isValid: -> @status in @validTypes

  # remove deletes an invitation from database
  remove$: permit 'send invitations',
    success: (client, callback) ->
      @remove callback

  # some selects result set for invitations, it adds group name automatically
  @some$: permit 'send invitations',
    success: (client, selector, options, callback) ->
      groupName = client.context.group or 'koding'

      selector or= {}
      selector.groupName = groupName # override group name in any case
      selector.status  or= 'pending'

      { limit }       = options
      options.sort  or= { createdAt : -1 }
      options.limit or= 25
      options.limit   = Math.min options.limit, 25 # admin can fetch max 25 record
      options.skip   ?= 0

      JInvitation.some selector, options, callback

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
      JUser               = require './user'
      JGroup              = require './group'

      { delegate }        = client.connection
      { invitations }     = options
      groupName           = client.context.group or 'koding'
      name                = getName delegate

      # check for membership
      JGroup.one { slug: groupName }, (err, group) ->
        return callback new KodingError err                   if err
        return callback new KodingError 'group doesnt exist'  if not group

        queue = invitations.map (invitation) -> ->

          { email, firstName, lastName, role } = invitation

          JInvitation.one { email, groupName }, (err, invitation) ->
            return callback new KodingError err  if err

            # do not send another invitation if the user is already invited
            # before
            return queue.fin()  if invitation

            isAlreadyMember group, email, (err, isMember) ->
              return callback new KodingError err  if err

              # do not send another invitation if the user is already a member
              # of the group
              return queue.fin()  if isMember

              hash = JUser.getHash email

              # eg: VJPj9gUQ
              code = shortid.generate()

              data =   {
                code
                hash
                email
                groupName
                role
              }
              # firstName and lastName are optional
              data.firstName = firstName  if firstName
              data.lastName  = lastName  if lastName

              invite = new JInvitation data
              invite.save (err) ->
                return callback new KodingError err  if err

                JInvitation.sendInvitationEmail client, invite, -> queue.fin()

        dash queue, callback


  # isAlreadyMember checks if the given email is already member of the given
  # group
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

    imgURL   = "#{protocol}//gravatar.com/avatar/#{profile.hash}?size=65&d=https://koding-cdn.s3.amazonaws.com/images/default.avatar.140.png&r=g"

    if profile.avatar
      imgURL = "#{protocol}//#{hostname}/-/image/cache?endpoint=crop&grow=false&width=65&height=65&url=#{encodeURIComponent profile.avatar}"

    properties =
      groupName    : invitation.groupName
      inviter      : inviter
      inviterImage : imgURL
      link         : groupLink + "Invitation/#{encodeURIComponent invitation.code}"

    Tracker.identifyAndTrack invitation.email, { subject : Tracker.types.INVITED_GROUP }, properties

    callback null


  getName = (delegate) ->

    { nickname, firstName, lastName } = delegate.profile

    name = nickname
    name = firstName              if firstName
    name = "#{name} #{lastName}"  if firstName and lastName

    return name
