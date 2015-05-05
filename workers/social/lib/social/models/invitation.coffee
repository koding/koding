{argv}    = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
jraphical = require 'jraphical'
crypto    = require 'crypto'
Bongo     = require "bongo"
Email     = require './email'

{ protocol, hostname } = KONFIG
{ secure, signature, dash } = Bongo

module.exports = class JInvitation extends jraphical.Module

  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/protected'


  {permit} = require './group/permissionset'

  @share()

  @set
    permissions     :
      'send invitations' : ['moderator', 'admin']
    indexes         :
      code          : 'unique'
      # TODO create a compound index on groupName and
    sharedMethods   :

      instance:
        remove:
          (signature Function)

      static:
        create:
          (signature Object, Function)
        byCode:
          (signature String, Function)

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

  remove$: permit 'send invitations',
    success: (client, callback) ->
      @remove callback

  accept$: secure (client, callback) ->
    { delegate } = client.connection
    @accept delegate, callback

  accept: (account, callback) ->
    operation = $set : { status: 'accepted' }
    @update operation, callback

  @byCode: (code, callback) ->
    @one {code}, callback

  # TODO - generate a better invitation code
  @generateInvitationCode = (email, group) ->
    code = crypto.createHmac 'sha1', 'kodingsecret'
    code.update email
    code.update group
    code.digest 'hex'

  @create: secure (client, options, callback) ->

    { groupName, delegate } = client.connection
    { invitations }         = options
    groupName             or= 'koding'
    name                    = getName delegate

    queue = invitations.map (invitation) => =>
      { email, firstName, lastName } = invitation

      code = @generateInvitationCode email, groupName

      invite = new JInvitation {
        code
        email
        groupName
        firstName
        lastName
      }

      invite.save (err) ->
        return callback err   if err

        options =
          to      : email,
          subject : Email.types.INVITE

        properties =
          groupName: groupName
          invitee  : name
          link     : "#{protocol}//#{groupName}.#{hostname}/Invitation/#{encodeURIComponent code}"

        Email.queue email, options, properties, -> queue.fin()

    dash queue, callback

  getName = (delegate) ->
    { nickname, firstName, lastName } = delegate.profile.nickname

    name = nickname

    if "#{firstName}" is not ""
      name = firstName

    if "#{lastName}" is not ""
      name = "#{name} #{lastName}"

    return name
