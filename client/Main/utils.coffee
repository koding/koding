utils.extend utils,

  groupifyLink: (href, withOrigin = no) ->

    {slug}   = KD.config.entryPoint
    {origin} = window.location
    href     = if slug is 'koding' then href else "#{slug}/#{href}"
    href     = "#{origin}/#{href}"  if withOrigin

    return href


  getPaymentMethodTitle: (billing)->
    # for convenience, accept either the payment method, or the billing object
    { billing } = billing  if billing.billing?

    { cardFirstName, cardLastName, cardType, cardNumber } = billing

    """
    #{ cardFirstName } #{ cardLastName } (#{ cardType } #{ cardNumber })
    """

  botchedUrlRegExp     : /(([a-zA-Z]+\:)?\/\/)+(\w+:\w+@)?([a-zA-Z\d.-]+\.[A-Za-z]{2,4})(:\d+)?(\/\S*)?/g
  webProtocolRegExp    : /^((http(s)?\:)?\/\/)/
  domainWithTLDPattern : /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}$/i
  subdomainPattern     : /^(?:[a-z0-9](?:[_\-](?![_\-])|[a-z0-9]){0,60}[a-z0-9]|[a-z0-9])$/i

  proxifyUrl:(url="", options={})->

    options.width   or= -1
    options.height  or= -1
    options.grow    or= yes

    if url is ""
      return "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="

    if options.width or options.height
      endpoint = "resize"
    if options.crop
      endpoint = "crop"

    fullurl = "#{KD.config.mainUri}/-/image/cache?" +
              "endpoint=#{endpoint or ''}&" +
              "grow=#{options.grow}&" +
              "width=#{options.width}&" +
              "height=#{options.height}&" +
              "url=#{encodeURIComponent url}"

    return fullurl

  # This function checks current user's preferred domain and
  # set's it to preferredDomainCookie
  setPreferredDomain:(account)->
    preferredDomainCookieName = 'kdproxy-preferred-domain'

    {preferredKDProxyDomain} = account
    if preferredKDProxyDomain and preferredKDProxyDomain isnt ""
      # if cookie name is already same do nothing
      return  if (Cookies.get preferredDomainCookieName) is preferredKDProxyDomain

      # set cookie name
      Cookies.set preferredDomainCookieName, preferredKDProxyDomain

      # there can be conflicts between first(which is defined below) route
      # and the currect builds router, so reload to main page from server
      location.reload(true)

  showMoreClickHandler:(event)->
    $trg = $(event.target)
    utils.stopDOMEvent event  if $trg.is ".more-link, .less-link"
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)

  applyTextExpansions: (text, shorten)->
    return "" unless text

    text = text.replace /&#10;/g, ' '

    # Expand URLs with intention to replace them after putShowMore
    {links,text} = @expandUrls text, yes

    text = utils.putShowMore text if shorten

    # Reinsert URLs into text
    if links? then for link,i in links
      text = text.replace "[tempLink#{i}]", link

    text = @expandUsernames text
    return text
    # @expandWwwDotDomains @expandUrls @expandUsernames text

  expandWwwDotDomains: (text) ->
    return null unless text
    text.replace /(^|\s)(www\.[A-Za-z0-9-_]+.[A-Za-z0-9-_:%&\?\/.=]+)/g, (_, whitespace, www) ->
      "#{whitespace}<a href='http://#{www}' target='_blank'>#{www}</a>"

  expandUsernames: (text, excludeSelector) ->
    # excludeSelector is a jQuery selector

    # as a JQuery selector, e.g. "pre"
    # means that all @s in <pre> tags will not be expanded

    return null unless text

    # default case for regular text
    if not excludeSelector
      text.replace /\B\@([\w\-]+)/gim, (u) ->
        username = u.replace "@", ""
        "<a href='/#{username}' class='profile-link'>#{u}</a>"

    # context-sensitive expansion
    else
      result = ""
      $(text).each (i, element) ->
        $element = $(element)
        elementCheck = $element.not excludeSelector
        parentCheck = $element.parents(excludeSelector).length is 0
        childrenCheck = $element.find(excludeSelector).length is 0
        if elementCheck and parentCheck and childrenCheck
          if $element.html()?
            replacedText =  $element.html().replace /\B\@([\w\-]+)/gim, (u) ->
              username = u.replace "@", ""
              u.link "/#{username}"
            $element.html replacedText
        result += $element.get(0).outerHTML or "" # in case there is a text-only element
      result

  expandUrls: (text,replaceAndYieldLinks=no) ->
    return null unless text

    links = []
    linkCount = 0

    urlGrabber = ///
    (?!\s)                                                      # leading spaces
    ([a-zA-Z]+://)                                              # protocol
    (\w+:\w+@|[\w|\d]+@|)                                       # username:password@
    ((?:[a-zA-Z\d]+(?:-[a-zA-Z\d]+)*\.)*)                       # subdomains
    ([a-zA-Z\d]+(?:[a-zA-Z\d]|-(?=[a-zA-Z\d]))*[a-zA-Z\d]?)     # domain
    \.                                                          # dot
    ([a-zA-Z]{2,4})                                             # top-level-domain
    (:\d+|)                                                     # :port
    (/\S*|)                                                     # rest of url
    (?!\S)
    ///g


    # This will change the original string to either a fully replaced version
    # or a version with temporary replacement strings that will later be replaced
    # with the expanded html tags
    text = text.replace urlGrabber, (url) ->

      url = url.trim()
      originalUrl = url

      # remove protocol and trailing path
      visibleUrl = url.replace(/(ht|f)tp(s)?\:\/\//,"").replace(/\/.*/,"")
      checkForPostSlash = /.*(\/\/)+.*\/.+/.test originalUrl # test for // ... / ...

      if not /[A-Za-z]+:\/\//.test url

        # url has no protocol
        url = '//'+url

      # Just yield a placeholder string for replacement later on
      # this is needed if the text should get shortened, add expanded
      # string to array at corresponding index
      if replaceAndYieldLinks
        links.push "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"
        "[tempLink#{linkCount++}]"
      else
        # yield the replacement inline (good for non-shortened text)
        "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"

    if replaceAndYieldLinks
      {
        links
        text
      }
    else
      text

  putShowMore: (text, l = 500)->
    shortenedText = utils.shortenText text,
      minLength : l
      maxLength : l + Math.floor(l/10)
      suffix    : ''

    # log "[#{text.length}:#{Encoder.htmlEncode(text).length}/#{shortenedText.length}:#{Encoder.htmlEncode(shortenedText).length}]"
    text = if Encoder.htmlEncode(text).length > Encoder.htmlEncode(shortenedText).length
      morePart = "<span class='collapsedtext hide'>"
      morePart += "<a href='#' class='more-link' title='Show more...'><i></i></a>"
      morePart += Encoder.htmlEncode(text).substr Encoder.htmlEncode(shortenedText).length
      morePart += "</span>"
      Encoder.htmlEncode(shortenedText) + morePart
    else
      Encoder.htmlEncode shortenedText

  shortenText: do ->
    tryToShorten = (longText, optimalBreak = ' ', suffix)->
      unless ~ longText.indexOf optimalBreak then no
      else
        "#{longText.split(optimalBreak).slice(0, -1).join optimalBreak}#{suffix ? optimalBreak}"

    (longText, options={})->
      return ''  unless longText
      minLength = options.minLength or 450
      maxLength = options.maxLength or 600
      suffix    = options.suffix     ? '...'

      longTextLength  = longText.length

      tempText = longText.slice 0, maxLength
      lastClosingTag = tempText.lastIndexOf "]"
      lastOpeningTag = tempText.lastIndexOf "["

      if lastOpeningTag <= lastClosingTag
        finalMaxLength = maxLength
      else
        finalMaxLength = lastOpeningTag

      return longText if longText.length < minLength or longText.length < maxLength

      longText = longText.substr 0, finalMaxLength

      # prefer to end the teaser at the end of a sentence (a period).
      # failing that prefer to end the teaser at the end of a word (a space).
      candidate = tryToShorten(longText, '. ', suffix) or tryToShorten longText, ' ', suffix

      return \
        if candidate?.length > minLength then candidate
        else longText

  expandTokens: (str = "", data) ->
    return  str unless tokenMatches = str.match /\|.+?\|/g

    tagMap = {}
    data.tags?.forEach (tag) ->
      unless tag.lazyNode?
        tagMap[tag.getId()] = tag

    viewParams = []
    for tokenString in tokenMatches
      [prefix, constructorName, id, title] = match[1].split /:/  if match = tokenString.match /^\|(.+)\|$/

      switch prefix
        when "#" then token = tagMap?[id]
        else continue

      unless token
        str = str.replace tokenString, "#{prefix}#{title}"
        continue

      domId     = utils.getUniqueId()
      itemClass = utils.getTokenClass prefix
      tokenView = new TokenView {domId, itemClass}, token
      tokenView.emit "viewAppended"
      str = str.replace tokenString, tokenView.getElement().outerHTML
      tokenView.destroy()

      viewParams.push {options: {domId, itemClass}, data: token}

    utils.defer ->
      for {options, data} in viewParams
        new TokenView options, data

    return  str

  getTokenClass: (prefix) ->
    switch prefix
      when "#" then TagLinkView

  getPlainActivityBody: (activity) ->
    {body} = activity
    tagMap = {}
    activity.tags?.forEach (tag) -> tagMap[tag.getId()] = tag

    return body.replace /\|(.+?)\|/g, (match, tokenString) ->
      [prefix, constructorName, id, title] = tokenString.split /:/

      switch prefix
        when "#" then token = tagMap?[id]

      return "#{prefix}#{if token then token.title else title or ''}"

  getMonthOptions : ->
    ((if i > 9 then { title : "#{i}", value : i} else { title : "0#{i}", value : i}) for i in [1..12])

  getYearOptions  : (min = 1900,max = Date::getFullYear())->
    ({ title : "#{i}", value : i} for i in [min..max])

  getFullnameFromAccount:(account, justName=no)->
    account or= KD.whoami()
    if account.type is 'unregistered'
      name = "a guest"
    else if justName
      name = account.profile.firstName
    else
      name = "#{account.profile.firstName} #{account.profile.lastName}"
    return Encoder.htmlEncode name.trim() or 'a Koding user'

  getNameFromFullname :(fullname)->
    fullname.split(' ')[0]

  warnAndLog: (msg, params)->
    warn msg, params
    ErrorLog.create msg, params

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

  # Version Compare
  # https://github.com/balupton/bal-util/blob/master/src/lib/compare.coffee
  # http://phpjs.org/functions/version_compare
  # MIT Licensed http://phpjs.org/pages/license
  versionCompare: (v1,operator,v2) ->
    i  = x = compare = 0
    vm =
      dev   : -6
      alpha : -5
      a     : -5
      beta  : -4
      b     : -4
      RC    : -3
      rc    : -3
      '#'   : -2
      p     : -1
      pl    : -1

    prepVersion = (v) ->
      v = ('' + v).replace(/[_\-+]/g, '.')
      v = v.replace(/([^.\d]+)/g, '.$1.').replace(/\.{2,}/g, '.')
      if !v.length then [-8]
      else v.split('.')

    numVersion = (v) ->
      if !v then 0
      else
        if isNaN(v) then vm[v] or -7
        else parseInt(v, 10)

    v1 = prepVersion(v1)
    v2 = prepVersion(v2)
    x  = Math.max(v1.length, v2.length)

    for i in [0..x]
      if (v1[i] == v2[i])
        continue

      v1[i] = numVersion(v1[i])
      v2[i] = numVersion(v2[i])

      if (v1[i] < v2[i])
        compare = -1
        break
      else if v1[i] > v2[i]
        compare = 1
        break

    return compare unless operator
    return switch operator
      when '>', 'gt'
        compare > 0
      when '>=', 'ge'
        compare >= 0
      when '<=', 'le'
        compare <= 0
      when '==', '=', 'eq', 'is'
        compare == 0
      when '<>', '!=', 'ne', 'isnt'
        compare != 0
      when '', '<', 'lt'
        compare < 0
      else
        null

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

  startRollbar: ->
    @replaceFromTempStorage "_rollbar"

  stopRollbar: ->
    @storeToTempStorage "_rollbar", window._rollbar
    window._rollbar = {push:->}

  startMixpanel: ->
    @replaceFromTempStorage "mixpanel"

  stopMixpanel: ->
    @storeToTempStorage "mixpanel", window.mixpanel
    window.mixpanel = {track:->}

  replaceFromTempStorage: (name)->
    if item = @tempStorage[name]
      window[item] = item
    else
      log "no #{name} in mainController temp storage"

  storeToTempStorage: (name, item)-> @tempStorage[name] = item

  tempStorage:-> KD.getSingleton("mainController").tempStorage

  applyGradient: (view, color1, color2) ->
    rules = [
      "-moz-linear-gradient(100% 100% 90deg, #{color2}, #{color1})"
      "-webkit-gradient(linear, 0% 0%, 0% 100%, from(#{color1}), to(#{color2}))"
    ]
    view.setCss "backgroundImage", rule for rule in rules

  getAppIcon:(name)->

    # resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    # if appManifest.devMode # TODO: change url to https when vm urls are ready for it
    #   resourceRoot = "http://#{KD.getSingleton('vmController').defaultVm}/.applications/#{utils.slugify name}/"


    # for size in [64, 128, 160, 256, 512]
    #   if icns and icns[String size]
    #     thumb = "#{resourceRoot}/#{icns[String size]}"
    #     break

    image  = if name is "Ace" then "icn-ace" else "default.app.thumb"
    thumb  = "#{KD.apiUri}/a/images/#{image}.png"

    img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : ->
        @getElement().setAttribute "src", "/a/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    return img


  compileCoffeeOnClient: (coffeeCode, callback = noop) ->
    require ["//cdnjs.cloudflare.com/ajax/libs/coffee-script/1.6.3/coffee-script.min.js"], (coffeeCompiler) ->
      callback coffeeCompiler.eval coffeeCode

  showSaveDialog: (container, callback = noop, options = {}) ->
    container.addSubView dialog = new KDDialogView
      cssClass      : KD.utils.curry "save-as-dialog", options.cssClass
      overlay       : yes
      container     : container
      height        : "auto"
      buttons       :
        Save        :
          style     : "solid green medium"
          callback  : => callback input, finderController, dialog
        Cancel      :
          style     : "solid medium nobg"
          callback  : =>
            finderController.stopAllWatchers()
            finderController.destroy()
            dialog.hide()

    dialog.on 'KDObjectWillBeDestroyed', -> container.ace?.focus()

    dialog.addSubView wrapper = new KDView
      cssClass : "kddialog-wrapper"

    wrapper.addSubView form = new KDFormView

    form.addSubView label = new KDLabelView
      title : options.inputLabelTitle or "Filename:"

    form.addSubView input = new KDInputView
      label        : label
      defaultValue : options.inputDefaultValue or ""

    form.addSubView labelFinder = new KDLabelView
      title : options.finderLabel or "Select a folder:"

    dialog.show()
    input.setFocus()

    finderController = KD.singletons['appManager'].get('Finder').create
      addAppTitle       : no
      treeItemClass     : IDE.FinderItem
      nodeIdPath        : 'path'
      nodeParentIdPath  : 'parentPath'
      foldersOnly       : yes
      contextMenu       : no
      loadFilesOnInit   : yes

    finder = finderController.getView()
    finderController.reset()

    form.addSubView finderWrapper = new KDView cssClass : "save-as-dialog save-file-container", null
    finderWrapper.addSubView finder
    finderWrapper.setHeight 200

  # TODO: Not totally sure what this is supposed to do, but I put it here
  #       to bypass awful hacks by Arvid Kahl:
  getEmbedType: (type) ->
    switch type
      when 'audio', 'xml', 'json', 'ppt', 'rss', 'atom'
        return 'object'

      # this is usually just a single image
      when 'photo','image'
        return 'image'

      # rich is a html object for things like twitter posts
      # link is fallback for things that may or may not have any kind of preview
      # or are links explicitly
      # also captures 'rich content' and makes regular links from that data
      when 'link', 'html'
        return 'link'

      # embedly supports many error types. we could display those to the user
      when 'error'
        log 'Embedding error '
        return 'error'

      else
        log "Unhandled content type '#{type}'"
        return 'error'

  getColorFromString:(str)->
    return [
      "#37B298", "#BA4B3A", "#F1C42C", "#DB4B00"
      "#009BCB", "#37B298", "#35485F", "#D35219"
      "#FDAB2E", "#19A2C4", "#37B298", "#BA4B3A"
      "#F1C42C", "#DB4B00", "#009BCB", "#B82F68"
    ][parseInt (md5.digest str)[0], 16]

  formatMoney: accounting.formatMoney

  stringToColor:(str)->
    hash = 0
    for i in [0...str.length]
      hash = str.charCodeAt(i) + ((hash << 5) - hash)

    color = '#'
    for i in [0...3]
      value = (hash >> (i * 8)) & 0xFF
      color += ('00' + value.toString(16)).substr(-2)

    return color

  postDummyStatusUpdate:->

    return if location.hostname isnt "localhost"
    body  = KD.utils.generatePassword(KD.utils.getRandomNumber(50), yes) + ' ' + dateFormat(Date.now(), "dddd, mmmm dS, yyyy, h:MM:ss TT")

    group = if KD.config.entryPoint?.type is 'group' and KD.config.entryPoint?.slug
    then KD.config.entryPoint.slug
    else 'koding'

    KD.singletons.socialapi.message.post {body, group}, (err,reply)=>
      unless err
      then KD.getSingleton("appManager").tell 'Activity', 'ownActivityArrived', reply
      else new KDNotificationView type : "mini", title : "There was an error, try again later!"

  # log ping times so we know if failure was due to user's slow
  # internet or our internals timing out
  logToExternalWithTime: (name, timeout)->
    KD.troubleshoot (times)->
      KD.logToExternal msg:"#{name} timed out in #{timeout}", pings:times

  # creates string from tag so that new status updates can
  # show the tags properly
  tokenizeTag: (tag)-> console.error "unimplemented feature"

  sortFiles: (a, b) ->

    { name: na } = a
    { name: nb } = b

    la = na.toLowerCase()
    lb = nb.toLowerCase()

    switch
      when la is lb
        switch
          when na is nb  then 0
          when na > nb   then 1
          when na < nb   then -1
      when la > lb       then 1
      when la < lb       then -1


  # // KontrolQuery is a structure of message sent to Kontrol. It is used for
  # // querying kites based on the incoming field parameters. Missing fields are
  # // not counted during the query (for example if the "version" field is empty,
  # // any kite with different version is going to be matched).
  # // Order of the fields is from general to specific.
  # type KontrolQuery struct {
  #     Username    string `json:"username"`
  #     Environment string `json:"environment"`
  #     Name        string `json:"name"`
  #     Version     string `json:"version"`
  #     Region      string `json:"region"`
  #     Hostname    string `json:"hostname"`
  #     ID          string `json:"id"`
  # }
  #
  # Structure taken from github.com/koding/kite/protocol/protocol.go

  splitKiteQuery: (query)->

    keys = [ "username", "environment", "name",
             "version", "region", "hostname", "id" ]

    query = query.replace /^\//, ""
    if (splitted = query.split '/').length is 7
      res = {}
      for s, i in splitted then res[keys[i]] = s
      return res

  doesQueryStringValid: (query)->
    return no  unless query
    query = query.replace /^\//, ""
    (query.split '/').length is 7


  doesEmailValid: (email) -> /@/.test email

  setPrototypeOf: Object.setPrototypeOf ? (obj, proto) ->
    obj.__proto__ = proto

  nicetime: do ->

    niceify = (duration)->

      past = no

      if duration < 0
        past     = yes
        duration = Math.abs duration

      duration = new Number(duration).toFixed 2
      durstr   = ''
      second   = 1
      minute   = second * 60
      hour     = minute * 60
      day      = hour * 24

      durstr = if duration < minute then 'less than a minute'
      else if duration < minute * 2 then 'about a minute';
      else if duration < hour       then Math.floor(duration / minute) + ' minutes'
      else if duration < hour * 2   then 'about an hour'
      else if duration < day        then 'about ' + Math.floor(duration / hour) + ' hours';
      else if duration < day * 2    then '1 day'
      else if duration < day * 365  then Math.floor(duration / day) + ' days';
      else 'over a year'

      durstr += ' ago'  if past

      return durstr

    (duration, to)->

      if not to
        niceify duration
      else if duration and to
        from = duration
        to   = to
        niceify to - from
      else if not duration and to
        from = new Date().getTime() / 1000
        to   = to
        niceify to - from

  # Chrome apps open links in a new browser window. OAuth authentication
  # relies on `window.opener` to be present to communicate back to the
  # parent window, which isn't available in a chrome app. Therefore, we
  # disable/change oauth behavior based on this flag: SA.
  oauthEnabled: -> window.name isnt "chromeapp"

  hasPermission: (name) ->

    (KD.config.permissions.indexOf name) >= 0


  # helper to generate an identifier
  # for non-important stuff.
  generateFakeIdentifier: (timestamp) ->
    "#{KD.whoami().profile.nickname}-#{timestamp}"


  # Generates a fake SocialMessage object
  generateDummyMessage: (body, timestamp) ->

    now       = new Date timestamp
    isoNow    = now.toISOString()

    fakeObject         =
      on               : -> this
      watch            : -> this
      body             : body
      account          : KD.whoami()
      createdAt        : isoNow
      updatedAt        : isoNow
      repliesCount     : 0
      meta             :
        createdAt      : now
        updatedAt      : now
      interactions     :
        like           :
          isInteracted : no
          actorsCount  : 0


