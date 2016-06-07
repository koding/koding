{ Model }   = require 'bongo'
jraphical   = require 'jraphical'
KodingError = require '../../error'

module.exports = class JRewardCampaign extends jraphical.Module

  # Examples for working with campaigns
  #
  # Warning: if campaign initial amount is 0
  #          then this is an infinite campaign
  #
  # # Create
  #
  # KD.remote.api.JRewardCampaign.create(
  #   {
  #     name           : "register",
  #     isActive       : true,
  #     type           : "disk",
  #     unit           : "MB",
  #     initialAmount  : 1000,
  #     maxAmount      : 1000000,
  #     perEventAmount : 500,
  #     startDate      : new Date(),
  #     endDate        : new Date("01/18/2015")
  #   }, function(err, campaign) {
  #     console.log(err, campaign);
  #   }
  # );
  #
  # # Find & Modify
  #
  # var campaign = null;
  #
  # KD.remote.api.JRewardCampaign.one(
  #   {
  #     name: "register"
  #   }, function(err, _campaign){
  #     if (err) {
  #       console.warn(err);
  #     }
  #     else if (_campaign) {
  #       campaign = _campaign;
  #       console.log("Campaign assigned to local variable `campaign`");
  #     }
  #     else {
  #       console.error("No campaign found.");
  #     }
  #   }
  # );
  #
  # if (campaign) {
  #   campaign.update({isActive: false}, log);
  # }
  #


  { signature, secure } = require 'bongo'

  @trait __dirname, '../../traits/protected'

  { permit } = require '../group/permissionset'

  @share()

  @set

    permissions         :
      'manage campaign' : []

    sharedEvents        :
      static            : []
      instance          : []

    indexes             :
      name              : 'unique'

    schema              :
      name              :
        type            : String
        required        : yes
      slug              : String
      isActive          : Boolean
      type              :
        type            : String
        default         : 'disk'
      unit              :
        type            : String
        default         : 'MB'
      initialAmount     :
        type            : Number
      maxAmount         :
        type            : Number
      perEventAmount    :
        type            : Number
      givenAmount       :
        type            : Number
        default         : 0
      startDate         :
        type            : Date
        default         : -> new Date
      endDate           :
        type            : Date
        default         : -> new Date
      createdAt         :
        type            : Date
        default         : -> new Date

    sharedMethods       :
      static            :
        create          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        one             :
          (signature Object, Function)
        some            :
          (signature Object, Object, Function)
        isValid         :
          (signature String, Function)
      instance          :
        update          : [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        remove          : [
          (signature Function)
          (signature Object, Function)
        ]

  # Helpers
  # -------

  DEFAULT_CAMPAIGN = 'register'

  deleteExistingCampaign = (data, callback) ->

    { name } = data

    return callback new KodingError 'Name not provided'  unless name

    JRewardCampaign.one { name }, (err, campaign) ->

      return callback err  if err
      return callback null unless campaign

      campaign.remove callback


  # Private Methods
  # ---------------

  # Static Methods

  @fetchCampaign = (campaignName, callback) ->

    unless callback
      [campaignName, callback] = [DEFAULT_CAMPAIGN, campaignName]

    JRewardCampaign.one { name: campaignName }, (err, campaign) ->
      return callback err  if err
      callback null, campaign


  # Instance Methods

  increaseGivenAmount: (size, callback) ->

    unless callback
      [size, callback] = [@perEventAmount, size]

    @update { $inc: { givenAmount: size } } , callback



  # Shared Methods
  # --------------

  # Static Methods

  @some$ = permit 'manage campaign',

    success: (client, selector, options, callback) ->
      @some selector, options, callback


  @one$ = permit 'manage campaign',

    success: (client, selector, callback) ->
      @one selector, callback


  @create = permit 'manage campaign',

    success: (client, data, callback) ->

      campaign = new JRewardCampaign data
      campaign.save (err) ->

        if err then callback err
        else callback null, campaign


  # Since we may need to use this method in pages where
  # users not registered yet, we are using secure instead
  # permit, from permission grid.
  @isValid = secure (client, campaignName, callback) ->

    unless callback
      [campaignName, callback] = [DEFAULT_CAMPAIGN, campaignName]

    JRewardCampaign.fetchCampaign campaignName, (err, campaign) ->

      return callback err  if err
      return callback null, { isValid: no }  unless campaign

      { maxAmount,
        givenAmount,
        initialAmount,
        perEventAmount,
        endDate, startDate } = campaign

      if Date.now() < startDate.getTime()
        return callback null, { isValid: no }

      # if date is valid
      if Date.now() > endDate.getTime()
        return callback null, { isValid: no }

      # if campaign initial amount is 0
      # then this is an infinite campaign
      if initialAmount is 0
        return callback null, { isValid: yes, campaign }

      # if campaign hit the limits
      if givenAmount + perEventAmount > maxAmount
        return callback null, { isValid: no }

      return callback null, { isValid: yes, campaign }


  # Instance Methods

  update$: permit 'manage campaign',
    success: (client, data, callback) ->
      @update { $set: data }, callback


  remove$: permit 'manage campaign',
    success: (client, data, callback) ->
      @remove callback
