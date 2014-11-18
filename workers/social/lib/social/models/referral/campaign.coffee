{Model}   = require 'bongo'
jraphical = require 'jraphical'

module.exports = class JReferralCampaign extends jraphical.Module

  {signature, secure} = require 'bongo'

  @trait __dirname, '../../traits/protected'

  {permit} = require '../group/permissionset'

  @share()

  @set

    permissions              :
      'manage campaign'      : []

    sharedEvents             :
      static                 : []
      instance               : []

    indexes                  :
      name                   : 'unique'

    schema                   :
      name                   :
        type                 : String
        required             : yes
      slug                   : String
      isActive               : Boolean
      campaignType           :
        type                 : String
        default              : "disk"
      campaignUnit           :
        type                 : String
        default              : "MB"
      campaignInitialAmount  :
        type                 : Number
      campaignMaxAmount      :
        type                 : Number
      campaignPerEventAmount :
        type                 : Number
      campaignGivenAmount    :
        type                 : Number
        default              : 0
      startDate              :
        type                 : Date
        default              : -> new Date
      endDate                :
        type                 : Date
        default              : -> new Date
      createdAt              :
        type                 : Date
        default              : -> new Date

    sharedMethods :
      static      :
        create    : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        some      :
          (signature Object, Object, Function)
        isCampaignValid:
          (signature String, Function)
      instance     :
        update     : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        remove     : [
          (signature Function)
          (signature Object, Function)
        ]

  @create = permit 'manage campaign',

    success: (client, data, callback) ->

      campaign = new JReferralCampaign data
      campaign.save (err)->

        if err then callback err
        else callback null, campaign


  update$: permit 'manage campaign',

    success: (client, data, callback)->

      @update $set: data, callback


  remove$: permit 'manage campaign',

    success: (client, data, callback)->

      @remove callback


  DEFAULT_CAMPAIGN = "register"


  @fetchCampaign = fetchCampaign = (campaignName, callback)->

    unless callback
      [campaignName, callback] = [DEFAULT_CAMPAIGN, campaignName]

    JReferralCampaign.one name: campaignName, (err, campaign) ->
      return callback err  if err
      callback null, campaign


  isCampaignValid = (campaignName, callback)->

    unless callback
      [campaignName, callback] = [DEFAULT_CAMPAIGN, campaignName]

    fetchCampaign campaignName, (err, campaign)->

      return callback err  if err
      return callback null, isValid: no  unless campaign

      { campaignMaxAmount,
        campaignGivenAmount,
        campaignInitialAmount,
        campaignPerEventAmount,
        endDate, startDate } = campaign

      if Date.now() < startDate.getTime()
        console.info "campaign #{campaignName} is not started yet"
        return callback null, isValid: no

      # if date is valid
      if Date.now() > endDate.getTime()
        console.info "date is not valid for campaign #{campaignName}"
        return callback null, isValid: no

      # if campaign initial amount is 0
      # then this is an infinite campaign
      if campaignInitialAmount is 0
        return callback null, { isValid: yes, campaign }

      # if campaign hit the limits
      if campaignGivenAmount + campaignPerEventAmount > campaignMaxAmount
        console.info "hit the max amount for #{campaignName} campaign"
        return callback null, isValid: no

      return callback null, { isValid: yes, campaign }


  @isCampaignValid = (campaignName, callback)->
    isCampaignValid campaignName, callback



  increaseGivenAmountSpace:(size, callback)->

    unless callback
      [size, callback] = [@campaignPerEventAmount, size]

    @update $inc: campaignGivenAmount: size , callback
