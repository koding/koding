{Model}   = require 'bongo'
jraphical = require 'jraphical'
module.exports = class JReferralCampaign extends jraphical.Module

  {signature, secure} = require 'bongo'
  @share()

  @set
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
      instance     :
        update     : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        remove     : [
          (signature Function)
          (signature Object, Function)
        ]
    sharedEvents    :
      static        : []
      instance      : []

  @create = secure (client, data, callback) ->
    checkPermission client, (err, res)=>
      return callback err if err
      customPartial = new JReferralCampaign data
      customPartial.save (err)->
        return callback err if err
        return callback null, customPartial

  checkPermission: checkPermission = (client, callback)->
    {context:{group}} = client
    JGroup = require "./group"
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
    fetchCampaign (err, campaign)->
      return callback err if err
      return callback null, no unless campaign

      { campaignGivenAmount,
        campaignInitialAmount
        endDate } = campaign

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
      unless campaign
        cmp = new JReferralCampaign
          name                  : campaignName
          slug                  : campaignName
          isActive              : true
          campaignPerEventAmount: 1024
          campaignInitialAmount : 0
          endDate               : new Date("Jan 28 2099 16:00:00 GMT")

        cmp.save (err)->
          return callback err if err
          return callback null, cmp
      else
        return callback null, campaign

   increaseGivenAmountSpace:(size, callback)->
    [size, callback] = [@campaignPerEventAmount, size] unless callback
    @update $inc : campaignGivenAmount: size , callback
