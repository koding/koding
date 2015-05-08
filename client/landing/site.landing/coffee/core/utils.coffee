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


  getLocationInfo: do (queue=[])->

    ip      = null
    country = null
    region  = null

    fail = ->

      for cb in queue
        cb { message: "Failed to fetch IP info." }

      queue = []

    (callback = noop)->

      if ip? and country? and region?
        callback null, { ip, country, region }
        return

      return  if (queue.push callback) > 1

      $.ajax
        url      : '//freegeoip.net/json/?callback=?'
        error    : fail
        timeout  : 1500
        dataType : 'json'
        success  : (data)->

          { ip, country_code, region_code } = data

          country = country_code
          region  = region_code

          for cb in queue
            cb null, { ip, country, region }

          queue = []


  clearKiteCaches: ->

    if window.localStorage?
      for kite in (Object.keys window.localStorage) when /^KITE_/.test kite
        delete window.localStorage[kite]


  # Chrome apps open links in a new browser window. OAuth authentication
  # relies on `window.opener` to be present to communicate back to the
  # parent window, which isn't available in a chrome app. Therefore, we
  # disable/change oauth behavior based on this flag: SA.
  oauthEnabled: -> window.name isnt "chromeapp"

  md5: do ->
    md5cycle = (x, k) ->
      a = x[0]
      b = x[1]
      c = x[2]
      d = x[3]
      a = ff(a, b, c, d, k[0], 7, -680876936)
      d = ff(d, a, b, c, k[1], 12, -389564586)
      c = ff(c, d, a, b, k[2], 17, 606105819)
      b = ff(b, c, d, a, k[3], 22, -1044525330)
      a = ff(a, b, c, d, k[4], 7, -176418897)
      d = ff(d, a, b, c, k[5], 12, 1200080426)
      c = ff(c, d, a, b, k[6], 17, -1473231341)
      b = ff(b, c, d, a, k[7], 22, -45705983)
      a = ff(a, b, c, d, k[8], 7, 1770035416)
      d = ff(d, a, b, c, k[9], 12, -1958414417)
      c = ff(c, d, a, b, k[10], 17, -42063)
      b = ff(b, c, d, a, k[11], 22, -1990404162)
      a = ff(a, b, c, d, k[12], 7, 1804603682)
      d = ff(d, a, b, c, k[13], 12, -40341101)
      c = ff(c, d, a, b, k[14], 17, -1502002290)
      b = ff(b, c, d, a, k[15], 22, 1236535329)
      a = gg(a, b, c, d, k[1], 5, -165796510)
      d = gg(d, a, b, c, k[6], 9, -1069501632)
      c = gg(c, d, a, b, k[11], 14, 643717713)
      b = gg(b, c, d, a, k[0], 20, -373897302)
      a = gg(a, b, c, d, k[5], 5, -701558691)
      d = gg(d, a, b, c, k[10], 9, 38016083)
      c = gg(c, d, a, b, k[15], 14, -660478335)
      b = gg(b, c, d, a, k[4], 20, -405537848)
      a = gg(a, b, c, d, k[9], 5, 568446438)
      d = gg(d, a, b, c, k[14], 9, -1019803690)
      c = gg(c, d, a, b, k[3], 14, -187363961)
      b = gg(b, c, d, a, k[8], 20, 1163531501)
      a = gg(a, b, c, d, k[13], 5, -1444681467)
      d = gg(d, a, b, c, k[2], 9, -51403784)
      c = gg(c, d, a, b, k[7], 14, 1735328473)
      b = gg(b, c, d, a, k[12], 20, -1926607734)
      a = hh(a, b, c, d, k[5], 4, -378558)
      d = hh(d, a, b, c, k[8], 11, -2022574463)
      c = hh(c, d, a, b, k[11], 16, 1839030562)
      b = hh(b, c, d, a, k[14], 23, -35309556)
      a = hh(a, b, c, d, k[1], 4, -1530992060)
      d = hh(d, a, b, c, k[4], 11, 1272893353)
      c = hh(c, d, a, b, k[7], 16, -155497632)
      b = hh(b, c, d, a, k[10], 23, -1094730640)
      a = hh(a, b, c, d, k[13], 4, 681279174)
      d = hh(d, a, b, c, k[0], 11, -358537222)
      c = hh(c, d, a, b, k[3], 16, -722521979)
      b = hh(b, c, d, a, k[6], 23, 76029189)
      a = hh(a, b, c, d, k[9], 4, -640364487)
      d = hh(d, a, b, c, k[12], 11, -421815835)
      c = hh(c, d, a, b, k[15], 16, 530742520)
      b = hh(b, c, d, a, k[2], 23, -995338651)
      a = ii(a, b, c, d, k[0], 6, -198630844)
      d = ii(d, a, b, c, k[7], 10, 1126891415)
      c = ii(c, d, a, b, k[14], 15, -1416354905)
      b = ii(b, c, d, a, k[5], 21, -57434055)
      a = ii(a, b, c, d, k[12], 6, 1700485571)
      d = ii(d, a, b, c, k[3], 10, -1894986606)
      c = ii(c, d, a, b, k[10], 15, -1051523)
      b = ii(b, c, d, a, k[1], 21, -2054922799)
      a = ii(a, b, c, d, k[8], 6, 1873313359)
      d = ii(d, a, b, c, k[15], 10, -30611744)
      c = ii(c, d, a, b, k[6], 15, -1560198380)
      b = ii(b, c, d, a, k[13], 21, 1309151649)
      a = ii(a, b, c, d, k[4], 6, -145523070)
      d = ii(d, a, b, c, k[11], 10, -1120210379)
      c = ii(c, d, a, b, k[2], 15, 718787259)
      b = ii(b, c, d, a, k[9], 21, -343485551)
      x[0] = add32(a, x[0])
      x[1] = add32(b, x[1])
      x[2] = add32(c, x[2])
      x[3] = add32(d, x[3])
      return
    cmn = (q, a, b, x, s, t) ->
      a = add32(add32(a, q), add32(x, t))
      add32 (a << s) | (a >>> (32 - s)), b
    ff = (a, b, c, d, x, s, t) ->
      cmn (b & c) | ((~b) & d), a, b, x, s, t
    gg = (a, b, c, d, x, s, t) ->
      cmn (b & d) | (c & (~d)), a, b, x, s, t
    hh = (a, b, c, d, x, s, t) ->
      cmn b ^ c ^ d, a, b, x, s, t
    ii = (a, b, c, d, x, s, t) ->
      cmn c ^ (b | (~d)), a, b, x, s, t
    md51 = (s) ->
      txt = ""
      n = s.length
      state = [
        1732584193
        -271733879
        -1732584194
        271733878
      ]
      i = undefined
      i = 64
      while i <= s.length
        md5cycle state, md5blk(s.substring(i - 64, i))
        i += 64
      s = s.substring(i - 64)
      tail = [
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
        0
      ]
      i = 0
      while i < s.length
        tail[i >> 2] |= s.charCodeAt(i) << ((i % 4) << 3)
        i++
      tail[i >> 2] |= 0x80 << ((i % 4) << 3)
      if i > 55
        md5cycle state, tail
        i = 0
        while i < 16
          tail[i] = 0
          i++
      tail[14] = n * 8
      md5cycle state, tail
      state

    # there needs to be support for Unicode here,
    # * unless we pretend that we can redefine the MD-5
    # * algorithm for multi-byte characters (perhaps
    # * by adding every four 16-bit characters and
    # * shortening the sum to 32 bits). Otherwise
    # * I suggest performing MD-5 as if every character
    # * was two bytes--e.g., 0040 0025 = @%--but then
    # * how will an ordinary MD-5 sum be matched?
    # * There is no way to standardize text to something
    # * like UTF-8 before transformation; speed cost is
    # * utterly prohibitive. The JavaScript standard
    # * itself needs to look at this: it should start
    # * providing access to strings as preformed UTF-8
    # * 8-bit unsigned value arrays.
    #
    md5blk = (s) -> # I figured global was faster.
      md5blks = [] # Andy King said do it this way.
      i = undefined
      i = 0
      while i < 64
        md5blks[i >> 2] = s.charCodeAt(i) + (s.charCodeAt(i + 1) << 8) + (s.charCodeAt(i + 2) << 16) + (s.charCodeAt(i + 3) << 24)
        i += 4
      md5blks
    rhex = (n) ->
      s = ""
      j = 0
      while j < 4
        s += hex_chr[(n >> (j * 8 + 4)) & 0x0f] + hex_chr[(n >> (j * 8)) & 0x0f]
        j++
      s
    hex = (x) ->
      i = 0

      while i < x.length
        x[i] = rhex(x[i])
        i++
      x.join ""
    md5 = (s) ->
      hex md51(s)

    # this function is much faster,
    #so if possible we use it. Some IEs
    #are the only ones I know of that
    #need the idiotic second function,
    #generated by an if clause.
    add32 = (a, b) ->
      (a + b) & 0xffffffff
    hex_chr = "0123456789abcdef".split("")
    unless md5("hello") is "5d41402abc4b2a76b9719d911017c592"
      add32 = (x, y) ->
        lsw = (x & 0xffff) + (y & 0xffff)
        msw = (x >> 16) + (y >> 16) + (lsw >> 16)
        (msw << 16) | (lsw & 0xffff)

    return md5


  trackEvent: (args...) ->

    return  unless @trackEligible()

    # send event#action as event for GA
    if args.length > 1
      {action} = args[1]
      args[1].event = args[0]  unless args[1].event

    # if event#action, send that or fallback to event
    event = if action? then action else args[0]
    analytics.track event, args[1]

  trackPage: (args) ->

    return  unless @trackEligible()

    {path} = args
    return  unless path

    title = @getFirstPartOfpath(path)
    analytics.page(title, {title:document.title, path})

  trackEligible: ->

    return analytics? and KD.config.environment is "production"

  getFirstPartOfpath: (path)-> return path.split('/')[1] or '/'

  getReferrer: ->
    match = location.pathname.match /\/R\/(.*)/
    return referrer  if match and referrer = match[1]


  getGroupNameFromLocation: ->

    { hostname } = location
    mainDomains = ['dev.koding.com', 'sandbox.koding.com', 'latest.koding.com', 'prod.koding.com']
    groupName = if hostname in mainDomains then 'koding'
    else if hostname.indexOf('.dev.koding.com') isnt -1
    then hostname.replace('.dev.koding.com', '').split('.').last
    else if hostname.indexOf('.koding.com') isnt -1
    then hostname.replace('.koding.com', '').split('.').last
    else 'koding'

    return groupName


  checkIfGroupExists: (groupName, callback) ->

    $.ajax
      url     : "/-/teams/#{groupName}"
      type    : 'post'
      success : (group) -> callback null, group
      error   : (err) -> callback err


  getEmailValidator: (options = {}) ->

    { container, password } = options

    container   : container
    event       : 'submit'
    messages    :
      required  : 'Please enter your email address.'
      email     : 'That doesn\'t seem like a valid email address.'
    rules       :
      required  : yes
      email     : yes
      available : (input, event) ->

        return  if event?.which is 9

        { required, email, minLength } = input.validationResults

        return  if required or minLength

        input.setValidationResult 'available', null
        email = input.getValue()
        if password
          passInput = password.input
          passValue = passInput.getValue()
        container.emit 'EmailIsNotAvailable'

        return  unless input.valid

        $.ajax
          url         : "/-/validate/email"
          type        : 'POST'
          data        :
            password  : passValue
            email     : email
          xhrFields   : withCredentials : yes
          success     : (res) ->

            return location.replace '/'  if res is 'User is logged in!'

            container.emit 'EmailIsAvailable'
            input.setValidationResult 'available', null

            container.emit 'EmailValidationPassed'  if res is yes

          error       : ({responseJSON}) ->
            container.emit 'EmailIsNotAvailable'
            input.setValidationResult 'available', "Sorry, \"#{email}\" is already in use!"

  checkedPasswords: {}
  checkPasswordStrength: KD.utils.debounce 300, (password, callback) ->

    return callback msg : 'No password specified!'  unless password
    return callback null, res                       if res = KD.utils.checkedPasswords[password]

    $.ajax
      url         : "/-/password-strength"
      type        : 'POST'
      data        : { password }
      success     : (res) ->
        KD.utils.checkedPasswords[res.password] = res
        callback null, res
      error       : ({responseJSON}) -> callback msg : responseJSON


  storeNewTeamData: (formName, formData) ->

    KD.team              ?= {}
    { team }              = KD
    team[formName]        = formData
    localStorage.teamData = JSON.stringify team


  clearTeamData: ->

    localStorage.teamData = null
    KD.team               = null


  getTeamData: ->

    return KD.team  if KD.team

    return {}  unless data = localStorage.teamData

    try
      team    = JSON.parse data
      KD.team = team

    return team  if team
    return {}


  createTeam: ->

    teamData = KD.utils.getTeamData()
    formData = {}

    for key, value of teamData
      for k, v of value
        if k.search('invitee') >= 0
          formData['invitees'] ?= v
          formData['invitees'] += ",#{v}"
        else
          formData[k] = v

    # manually add legacy fields - SY
    formData.agree           = 'on'
    formData.passwordConfirm = formData.password
    formData.redirect        = "#{location.protocol}//#{formData.slug}.#{location.host}?username=#{formData.username}"

    $.ajax
      url       : "/-/teams/create"
      data      : formData
      type      : 'POST'
      xhrFields : withCredentials : yes
      success   : ->
        KD.utils.clearTeamData()
        location.href = formData.redirect
      error     : ({responseText}) =>
        new KDNotificationView title : responseText