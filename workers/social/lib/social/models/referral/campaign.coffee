{Model}   = require 'bongo'
jraphical = require 'jraphical'
module.exports = class JReferralCampaign extends jraphical.Module

  {signature, secure} = require 'bongo'
  @share()

  @set
    sharedEvents             :
      static                 : []
      instance               : []
    indexes                  :
      name                   : 'unique'
    schema                   :
      name                   : String
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

  @create = secure (client, data, callback) ->
    checkPermission client, (err, res)=>
      return callback err if err
      campaign = new JReferralCampaign data
      campaign.save (err)->
        return callback err if err
        return callback null, campaign

  checkPermission: checkPermission = (client, callback)->
    {context:{group}} = client
    JGroup = require "../group"
    JGroup.one {slug:group}, (err, group)=>
      return callback err if err
      return callback new Error "group not found" unless group
      group.canEditGroup client, (err, hasPermission)=>
        return callback err if err
        return callback new Error "Can not edit group" unless hasPermission
        return callback null, yes

  update$: secure (client, data, callback)->
    @checkPermission client, (err, res)=>
      return callback err if err
      @update {$set:data}, callback

  remove$: secure (client, callback)->
    @checkPermission client, (err, res)=>
      return callback err if err
      @remove callback

  REGISTER_CAMPAIGN = "register"

  isCampaignValid = (campaignName, callback)->
    [campaignName, callback] = [REGISTER_CAMPAIGN, campaignName] unless callback
    fetchCampaign campaignName, (err, campaign)->
      return callback err if err
      return callback null, no unless campaign

      { campaignGivenAmount,
        campaignInitialAmount
        endDate, startDate } = campaign

      if Date.now() < startDate.getTime()
        console.info "campaign is not started yet"
        return callback null, no

      # if date is valid
      if Date.now() > endDate.getTime()
        console.info "date is not valid for campaign"
        return callback null, no

      # if campaign initial amount is 0
      # then this is an infinite campaign
      if campaignInitialAmount is 0
        return callback null, yes, campaign

      # if campaign has more disk space
      if campaignGivenAmount > campaignInitialAmount
        return callback null, no

      return callback null, yes, campaign

  @isCampaignValid = isCampaignValid

  @fetchCampaignDiskSize = (callback)->
    @isCampaignValid (err, valid, campaign)->
      return callback err if err
      # if campaign is not valid just send 256 as disk size
      return callback null, campaign?.campaignPerEventAmount or 256

  @fetchCampaign = fetchCampaign = (campaignName, callback)->
    [campaignName, callback] = [REGISTER_CAMPAIGN, campaignName] unless callback
    JReferralCampaign.one {name: campaignName}, (err, campaign) ->
      return callback err if err
      return callback null, no  unless campaign
      return callback null, campaign

   increaseGivenAmountSpace:(size, callback)->
    [size, callback] = [@campaignPerEventAmount, size] unless callback
    size = size * 4
    @update $inc : campaignGivenAmount: size , callback
