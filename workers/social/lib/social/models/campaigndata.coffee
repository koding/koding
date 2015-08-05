jraphical = require 'jraphical'

emailsanitize = require './user/emailsanitize'

module.exports = class JCampaignData extends jraphical.Module

  @set
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

    return callback message: 'Email is missing!'          unless data.email
    return callback message: 'Campaign info is missing!'  unless data.campaign

    { campaign, email } = data

    email = emailsanitize email

    JCampaignData.one { campaign, email }, {}, (err, model) ->

      return callback err                          if err
      return callback message: 'Already applied!'  if model

      model = new JCampaignData data
      model.save callback


