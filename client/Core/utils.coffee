utils.extend utils,

  ###
  password-generator
  Copyright(c) 2011 Bermi Ferrer <bermi@bermilabs.com>
  MIT Licensed
  ###
  generatePassword: do ->

    letter = /[a-zA-Z]$/;
    vowel = /[aeiouAEIOU]$/;
    consonant = /[bcdfghjklmnpqrstvwxyzBCDFGHJKLMNPQRSTVWXYZ]$/;

    (length = 10, memorable = yes, pattern = /\w/, prefix = '')->

      return prefix if prefix.length >= length

      if memorable
        pattern = if consonant.test(prefix) then vowel else consonant

      n   = (Math.floor(Math.random() * 100) % 94) + 33
      chr = String.fromCharCode(n)
      chr = chr.toLowerCase() if memorable

      unless pattern.test chr
        return utils.generatePassword length, memorable, pattern, prefix

      return utils.generatePassword length, memorable, pattern, "" + prefix + chr

  isNavigatorApple: ->
    if navigator.platform.match(/(Mac|iPhone|iPod|iPad)/i) then yes else no

  getDummyName:->
    u  = KD.utils
    gr = u.getRandomNumber
    gp = u.generatePassword
    gp(gr(10), yes)

  generateDummyUserData:->

    u  = KD.utils

    uniqueness = (Date.now()+"").slice(6)
    return formData   =
      agree           : "on"
      email           : "sinanyasar+#{uniqueness}@gmail.com"
      firstName       : u.getDummyName()
      lastName        : u.getDummyName()
      # inviteCode      : "twitterfriends"
      password        : "123123123"
      passwordConfirm : "123123123"
      username        : uniqueness

  registerDummyUser:->

    return if location.hostname is "koding.com"

    u  = KD.utils

    KD.remote.api.JUser.register u.generateDummyUserData(), => location.reload yes



  # Chrome apps open links in a new browser window. OAuth authentication
  # relies on `window.opener` to be present to communicate back to the
  # parent window, which isn't available in a chrome app. Therefore, we
  # disable/change oauth behavior based on this flag: SA.
  oauthEnabled: -> window.name isnt "chromeapp"


  # Arguments:
  #
  #  object      : an object
  #
  #  options     :
  #    maxDepth  : maximum depth for object walk (default: 24)
  #    separator : char to use depth separator   (default: \t)
  #
  # If fails, returns [Object object]
  #
  objectToString: (object, options = {})->

    { maxDepth, separator } = options

    maxDepth  ?= 24
    separator ?= "\t"

    stringfy = ->

      depth  = 0
      ccache = []

      (key, value)->

        return if depth > maxDepth
        return 'undefined'  unless value?

        depth++

        if typeof value is 'object'
          return  unless ccache.indexOf value is -1
          ccache.push value
        else
          value = value.toString()

        return value

    try
      string = JSON.stringify object, stringfy(), separator
    catch e
      console.warn "Failed to stringfy:", e, object
      string = "[Object object]"

    return string


  selectText: (el) ->

    if document.selection
      range = document.body.createTextRange()
      range.moveToElementText el
      range.select()

    else if window.getSelection
      range = document.createRange()
      range.selectNode el
      window.getSelection().addRange range
