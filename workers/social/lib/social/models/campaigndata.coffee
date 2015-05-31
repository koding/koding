jraphical = require 'jraphical'

module.exports = class JCampaignData extends jraphical.Module

  @set
    schema       :
      email      :
        type     : String
        required : yes
        validate : require('./name').validateEmail
        set      : (value) -> value.toLowerCase()
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

    model = new JCampaignData data
    model.save callback


