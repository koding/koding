jraphical   = require 'jraphical'
KodingError = require '../error'

emailsanitize = require './user/emailsanitize'

module.exports = class JCampaignData extends jraphical.Module

  @set
    sharedEvents :
      static     : [ ]
      instance   : [ ]
    schema       :
      email      :
        type     : String
        required : yes
        validate : require('./name').validateEmail
        set      : emailsanitize
      campaign   :
        required : yes
        type     : String
      username   :
        type     : String
      createdAt  :
        type     : Date
        default  : -> new Date
      payload    :
        type     : Object


  @add: (data, callback) ->

    return callback new KodingError 'Email is missing!'          unless data.email
    return callback new KodingError 'Campaign info is missing!'  unless data.campaign

    { campaign, email } = data

    email = emailsanitize email

    JCampaignData.one { campaign, email }, {}, (err, model) ->

      return callback err                          if err
      return callback new KodingError 'Already applied!'  if model

      model = new JCampaignData data
      model.save callback
