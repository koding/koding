Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class SocialChannel extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetchActivity     :
          (signature Object, Function)
        fetchParticipants :
          (signature Object, Function)

    schema             :
      id               : Number
      name             : String
      creatorId        : Number
      group            : String
      purpose          : String
      secretKey        : String
      type             : String
      privacy          : String
      createdAt        : Date
      updatedAt        : Date

  JAccount = require '../account'

  {fetchGroup} = require "./helper"


  @fetchActivity = secure (client, options = {}, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      {fetchChannelActivity} = require './requests'

      data =
        channelId: options.id
        accountId: socialApiId

      fetchChannelActivity data, (err, activities)->
        callback err, activities
