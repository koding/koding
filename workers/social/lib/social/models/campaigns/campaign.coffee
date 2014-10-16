JStorage = require './../storage'
{Model}  = require 'bongo'

module.exports = class JCampaign extends JStorage

  {signature, secure} = require 'bongo'

  @share()

  @set
    sharedMethods :
      static      :
        create    : (signature Object, Function)
        activate  : (signature String, Function)
        deactivate: (signature String, Function)


  permit = (client, callback) ->

    {connection: {delegate:account}} = client

    account.fetchRole client, (err, role) ->

      return callback message : 'Permission denied!'  if err or role isnt 'super-admin'

      callback null, yes


  toggleCampaign = (name, state, callback) ->

    JStorage.one { name }, (err, campaign) =>

      return callback err                            if err
      return callback message : 'No such campaign!'  unless campaign

      if state
      then campaign.update { $set : 'content.active' : state }, callback
      else campaign.update { $unset : 'content.active' : state }, callback


  @get = (name, callback) ->

    return callback message : 'Name is missing!'  unless name

    JStorage.one { name }, (err, campaign) ->

      return callback null, no  if err or not campaign

      callback null, campaign


  @create = secure (client, options, callback) ->

    permit client, (err, permitted) ->

      return callback err                                   unless permitted
      return callback message : 'Name is missing!'          unless options.name
      return callback message : 'Content is missing!'       unless options.content
      return callback message : 'Content is not an object!' if 'object' isnt typeof options.content

      options.content.active = yes

      storage = new JStorage options
        .save callback


  @activate = secure (client, name, callback) ->

    permit client, (err, permitted) =>

      return callback err  unless permitted

      toggleCampaign name, yes, callback


  @deactivate = secure (client, name, callback) ->

    permit client, (err, permitted) =>

      return callback err  unless permitted

      toggleCampaign name, no, callback
