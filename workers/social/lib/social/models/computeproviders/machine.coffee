{ Module }     = require 'jraphical'
{ revive }     = require './computeutils'

module.exports = class JMachine extends Module

  { ObjectId, signature, daisy } = require 'bongo'

  @trait __dirname, '../../traits/protected'
  {permit} = require '../group/permissionset'

  @share()

  @set

    indexes             :
      kiteId            : 'unique'

    sharedEvents        :
      static            : [ ]
      instance          : [ ]

    sharedMethods       :
      static            :
        one             :
          (signature String, Function)
      instance          :
        reviveUsers     :
          (signature Function)

    permissions         :
      'list machines'   : ['member']
      'populate users'  : ['member']

    schema              :

      kiteId            :
        type            : String

      provider          :
        type            : String
        required        : yes

      label             :
        type            : String
        default         : ""

      initScript        :
        type            : String

      users             : Array
      groups            : Array

      state             :
        type            : String
        enum            : ["Wrong type specified!",
          ["active", "not-initialized", "removed", "suspended"]
        ]
        default         : "not-initialized"

      meta              : Object


  @one$: permit 'list machines',

    success: revive

      shouldReviveClient   : yes
      shouldReviveProvider : no

    , (client, machineId, callback)->

      { r: { group, user } } = client

      selector =
        _id      : machineId
        users    : $elemMatch: id: user.getId()
        groups   : $elemMatch: id: group.getId()

      JMachine.one selector, (err, machine)->
        callback err, machine

  reviveUsers: permit 'populate users',

  success: (client, callback)->

    JUser = require '../user'

    accounts = []
    queue    = []

    (@users ? []).forEach (_user)->
      queue.push -> JUser.one _id: _user.id, (err, user)->
        if not err? and user
          user.fetchOwnAccount (err, account)->
            if not err? and account?
              accounts.push account
            queue.next()
        else
          queue.next()

    queue.push =>
      callback null, accounts

    daisy queue
