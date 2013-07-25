# utils singleton
# -------------------------
#
# -------------------------

__utils =

  idCounter : 0

  formatPlural:(count, noun)->
    "#{count or 0} #{if count is 1 then noun else Inflector.pluralize noun}"

  selectText:(element, selectionStart, selectionEnd)->
    doc   = document
    if doc.body.createTextRange
      range = document.body.createTextRange()
      range.moveToElementText element
      range.select()
    else if window.getSelection
      selection = window.getSelection()
      range     = document.createRange()
      range.selectNodeContents element
      selection.removeAllRanges()
      selection.addRange range

  getCallerChain:(args, depth)->
    {callee:{caller}} = args
    chain = [caller]
    while depth-- and caller = caller?.caller
      chain.push caller
    chain

  getUniqueId: do -> i = 0; -> "kd-#{i++}"

  getRandomNumber :(range)->
    range = range or 1000000
    Math.floor Math.random()*range+1

  uniqueId : (prefix)->
    id = __utils.idCounter++
    if prefix? then "#{prefix}#{id}" else id

  getRandomRGB :->
    {getRandomNumber} = @
    "rgb(#{getRandomNumber(255)},#{getRandomNumber(255)},#{getRandomNumber(255)})"

  getRandomHex : ->
    # hex = (Math.random()*0xFFFFFF<<0).toString(16)
    hex = (Math.random()*0x999999<<0).toString(16)
    while hex.length < 6
      hex += "0"
    "##{hex}"

  trimIllegalChars :(word)->

  curryCssClass:(obligatoryClass, optionalClass)-> obligatoryClass + if optionalClass then ' ' + optionalClass else ''

  parseQuery:do->
    params  = /([^&=]+)=?([^&]*)/g    # for chunking the key-val pairs
    plusses = /\+/g                   # for converting plus signs to spaces
    decode  = (str)-> decodeURIComponent str.replace plusses, " "
    parseQuery = (queryString = location.search.substring 1)->
      result = {}
      result[decode m[1]] = decode m[2]  while m = params.exec queryString
      result

  stringifyQuery:do->
    spaces = /\s/g
    encode =(str)-> encodeURIComponent str.replace spaces, "+"
    stringifyQuery = (obj)->
      Object.keys(obj).map((key)-> "#{encode key}=#{encode obj[key]}").join('&').trim()

  capAndRemovePeriods:(path)->
    newPath = for arg in path.split "."
      arg.capitalize()
    newPath.join ""

  slugify:(title = "")->
    url = String(title)
      .toLowerCase()                # change everything to lowercase
      .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
      .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens

  stripTags:(value)->
    value.replace /<(?:.|\n)*?>/gm, ''

  decimalToAnother:(n, radix) ->
    hex = []
    for i in [0..10]
      hex[i+1] = i

    s = ''
    a = n
    while a >= radix
      b = a % radix
      a = Math.floor a / radix
      s += hex[b + 1]

    s += hex[a + 1]
    n = s.length
    t = ''
    for i in [0...n]
      t = t + s.substring n - i - 1, n - i
    s = t
    s

  proxifyUrl:(url="")->
    if url is ""
    then "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
    else "#{location.protocol}//#{location.host}/-/imageProxy?url=#{encodeURIComponent(url)}"

  applyMarkdown: (text)->
    # problems with markdown so far:
    # - links are broken due to textexpansions (images too i guess)
    return null unless text

    marked.setOptions
      gfm       : true
      pedantic  : false
      sanitize  : true
      highlight :(text, lang)->
        if hljs.LANGUAGES[lang]?
        then hljs.highlight(lang,text).value
        else text

    text = marked Encoder.htmlDecode text

    sanitizeText = $(text)

    # Proxify images

    sanitizeText.find("img").each (i,element) =>
      src = element.getAttribute 'src'
      element.setAttribute "src", src?.replace /.*/, @proxifyUrl

    # Give all outbound links a target blank
    sanitizeText.find("a").each (i,element) =>
      unless /^(#!)/.test $(element).attr("href")
        $(element).attr("target", "_blank")

    text = $("<div />").append(sanitizeText.clone()).remove().html() # workaround for .html()


  applyLineBreaks: (text)->
    return null unless text
    text.replace /\n/g, "<br />"

  showMoreClickHandler:(event)->
    $trg = $(event.target)
    more = "span.collapsedtext a.more-link"
    less = "span.collapsedtext a.less-link"
    $trg.parent().addClass("show").removeClass("hide") if $trg.is(more)
    $trg.parent().removeClass("show").addClass("hide") if $trg.is(less)

  applyTextExpansions: (text, shorten)->
    return null unless text

    text = text.replace /&#10;/g, ' '

    # Expand URLs with intention to replace them after putShowMore
    {links,text} = @expandUrls text, yes

    text = __utils.putShowMore text if shorten

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

  expandUsernames: (text,sensitiveTo=no) ->
    # sensitiveTo is a string containing parent elements whose children
    # should not receive name expansion

    # as a JQuery selector, e.g. "pre"
    # means that all @s in <pre> tags will not be expanded

    return null unless text

    # default case for regular text
    if not sensitiveTo
      text.replace /\B\@([\w\-]+)/gim, (u) ->
        username = u.replace "@", ""
        u.link "/#{username}"
    # context-sensitive expansion
    else
      result = ""
      $(text).each (i,element)->
        if ($(element).parents(sensitiveTo).length is 0) and not ($(element).is sensitiveTo)
          if $(element).html()?
            replacedText =  $(element).html().replace /\B\@([\w\-]+)/gim, (u) ->
              username = u.replace "@", ""
              u.link "/#{username}"
            $(element).html replacedText
        result += $(element).get(0).outerHTML or "" # in case there is a text-only element
      result

  expandTags: (text) ->
    return null unless text
    text.replace /[#]+[A-Za-z0-9-_]+/g, (t) ->
      tag = t.replace "#", ""
      "<a href='#!/topic/#{tag}' class='ttag'><span>#{tag}</span></a>"

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
    shortenedText = __utils.shortenText text,
      minLength : l
      maxLength : l + Math.floor(l/10)
      suffix    : ''

    # log "[#{text.length}:#{Encoder.htmlEncode(text).length}/#{shortenedText.length}:#{Encoder.htmlEncode(shortenedText).length}]"
    text = if Encoder.htmlEncode(text).length > Encoder.htmlEncode(shortenedText).length
      morePart = "<span class='collapsedtext hide'>"
      morePart += "<a href='#' class='more-link' title='Show more...'>Show more...</a>"
      morePart += Encoder.htmlEncode(text).substr Encoder.htmlEncode(shortenedText).length
      morePart += "<a href='#' class='less-link' title='Show less...'>...show less</a>"
      morePart += "</span>"
      Encoder.htmlEncode(shortenedText) + morePart
    else
      Encoder.htmlEncode shortenedText

  shortenText:do ->
    tryToShorten = (longText, optimalBreak = ' ', suffix)->
      unless ~ longText.indexOf optimalBreak then no
      else
        "#{longText.split(optimalBreak).slice(0, -1).join optimalBreak}#{suffix ? optimalBreak}"
    (longText, options={})->
      return unless longText
      minLength = options.minLength or 450
      maxLength = options.maxLength or 600
      suffix    = options.suffix     ? '...'

      longTextLength  = Encoder.htmlDecode(longText).length
      longText = Encoder.htmlDecode longText

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

      # Encoder.htmlDecode Encoder.htmlEncode \
      #   if candidate?.length > minLength then candidate
      #   else longText

      return \
        if candidate?.length > minLength then candidate
        else longText

  getMonthOptions : ->
    ((if i > 9 then { title : "#{i}", value : i} else { title : "0#{i}", value : i}) for i in [1..12])

  getYearOptions  : (min = 1900,max = Date::getFullYear())->
    ({ title : "#{i}", value : i} for i in [min..max])

  getFullnameFromAccount:(account)->
    {firstName, lastName} = account.profile
    return "#{firstName} #{lastName}"

  getNameFromFullname :(fullname)->
    fullname.split(' ')[0]

  wait: (duration, fn)->
    if "function" is typeof duration
      fn = duration
      duration = 0
    setTimeout fn, duration

  killWait:(id)-> clearTimeout id if id

  repeat: (duration, fn)->
    if "function" is typeof duration
      fn = duration
      duration = 500
    setInterval fn, duration

  killRepeat:(id)-> clearInterval id

  defer:do ->
    # this was ported from browserify's implementation of "process.nextTick"
    queue = []
    if window?.postMessage and window.addEventListener
      window.addEventListener "message", ((ev) ->
        if ev.source is window and ev.data is "kd-tick"
          ev.stopPropagation()
          do queue.shift()  if queue.length > 0
      ), yes
      (fn) -> queue.push fn; window.postMessage "kd-tick", "*"
    else
      (fn) -> setTimeout fn, 1


  getCancellableCallback:(callback)->
    cancelled = no
    kallback = (rest...)-> callback rest...  unless cancelled
    kallback.cancel = -> cancelled = yes
    kallback

  # ~ GG
  # Returns a new callback which calls the failcallback if
  # first callback not finish its job in given timeout (default is 5000ms)
  #
  # Usage:
  #
  # Let assume that you have this:
  #
  #   asyncFunc (data)->
  #     doSomethingWith data
  #
  # To set a timeout for it eg. 500ms:
  #
  #   asyncFunc getTimedOutCallBack (data)->
  #     doSomethingWith data
  #   , ->
  #     console.log "asyncFunc is not responded in 500ms."
  #   , 500
  #
  getTimedOutCallback:(callback, failcallback, timeout=5000)->
    cancelled = no
    kallback  = (rest...)->
      clearTimeout fallbackTimer
      callback rest...  unless cancelled

    fallback = (rest...)->
      failcallback rest...  unless cancelled
      cancelled = yes

    fallbackTimer = setTimeout fallback, timeout
    kallback

  # Returns a new callback which calls the failcallback if
  # first callback doesn't finish its job within timeout.
  #
  # Also, keeps track of start and end times.
  #
  # Let's assume that you have this:
  #
  #   asyncFunc (data)-> doSomethingWith data
  #
  # To set a timeout for 500ms:
  #
  #   asyncFunc ,\
  #     KD.utils.getTimedOutCallbackOne
  #       name     :"asyncFunc" // optional, logs to KD.utils.timers
  #       timeout  : 500        // defaults to 5000
  #       onSucess : (data)->
  #       onTimeout: ->
  #       onResult : ->         // called when result comes after timeout
  getTimedOutCallbackOne: (options={})->
    timerName = options.name      or "undefined"
    timeout   = options.timeout   or 10000
    onSuccess = options.onSuccess or ->
    onTimeout = options.onTimeout or ->
    onResult  = options.onResult  or ->

    timedOut = no
    kallback = (rest...)=>
      clearTimeout fallbackTimer
      @updateLogTimer timerName, fallbackTimer, Date.now()

      if timedOut then onResult rest... else onSuccess rest...

    fallback = (rest...)=>
      timedOut = yes
      @updateLogTimer timerName, fallbackTimer

      onTimeout rest...

    fallbackTimer = setTimeout fallback, timeout
    @logTimer timerName, fallbackTimer, Date.now()

    kallback.cancel =-> clearTimeout fallbackTimer
    kallback

  notifyAndEmailVMTurnOnFailureToSysAdmin: (vmName, reason)->
    if window.localStorage.notifiedSysAdminOfVMFailureTime
      if parseInt(window.localStorage.notifiedSysAdminOfVMFailureTime, 10)+(1000*60*60)>Date.now()
        return

    window.localStorage.notifiedSysAdminOfVMFailureTime = Date.now()

    new KDNotificationView
      title:"Sorry, your vm failed to turn on. An email has been sent to a sysadmin."

    KD.whoami().sendEmailVMTurnOnFailureToSysAdmin vmName, reason

  logTimer:(timerName, timerNumber, startTime)->
    log "logTimer name:#{timerName}"

    @timers[timerName] ||= {}
    @timers[timerName][timerNumber] =
      start  : startTime
      status : "started"

  updateLogTimer:(timerName, timerNumber, endTime)->
    timer     = @timers[timerName][timerNumber]
    status    = if endTime then "ended" else "failed"
    startTime = timer.start
    elapsed   = endTime-startTime
    timer     =
      start   : startTime
      end     : endTime
      status  : status
      elapsed : elapsed

    @timers[timerName][timerNumber] = timer

    log "updateLogTimer name:#{timerName}, status:#{status} elapsed:#{elapsed}"

  timers: {}

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
        return __utils.generatePassword length, memorable, pattern, prefix

      return __utils.generatePassword length, memorable, pattern, "" + prefix + chr

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

  registerDummyUser:->

    return if location.hostname isnt "localhost"

    u  = KD.utils

    uniqueness = (Date.now()+"").slice(6)
    formData   =
      agree           : "on"
      email           : "sinanyasar+#{uniqueness}@gmail.com"
      firstName       : u.getDummyName()
      lastName        : u.getDummyName()
      inviteCode      : "twitterfriends"
      password        : "123123123"
      passwordConfirm : "123123123"
      username        : uniqueness

    KD.remote.api.JUser.register formData, => location.reload yes

  postDummyStatusUpdate:->

    return if location.hostname isnt "localhost"

    body  = KD.utils.generatePassword(KD.utils.getRandomNumber(50), yes) + ' ' + dateFormat(Date.now(), "dddd, mmmm dS, yyyy, h:MM:ss TT")
    if KD.config.entryPoint?.type is 'group' and KD.config.entryPoint?.slug
      group = KD.config.entryPoint.slug
    else
      group = 'koding'

    KD.remote.api.JStatusUpdate.create {body, group}, (err,reply)=>
      unless err
        KD.getSingleton("appManager").tell 'Activity', 'ownActivityArrived', reply
      else
        new KDNotificationView type : "mini", title : "There was an error, try again later!"

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

  stopDOMEvent :(event)->
    return no  unless event
    event.preventDefault()
    event.stopPropagation()
    return no

  utf8Encode:(string)->
    string = string.replace(/\r\n/g, "\n")
    utftext = ""
    n = 0

    while n < string.length
      c = string.charCodeAt(n)
      if c < 128
        utftext += String.fromCharCode(c)
      else if (c > 127) and (c < 2048)
        utftext += String.fromCharCode((c >> 6) | 192)
        utftext += String.fromCharCode((c & 63) | 128)
      else
        utftext += String.fromCharCode((c >> 12) | 224)
        utftext += String.fromCharCode(((c >> 6) & 63) | 128)
        utftext += String.fromCharCode((c & 63) | 128)
      n++
    utftext

  utf8Decode:(utftext)->
    string = ""
    i = 0
    c = c1 = c2 = 0
    while i < utftext.length
      c = utftext.charCodeAt(i)
      if c < 128
        string += String.fromCharCode(c)
        i++
      else if (c > 191) and (c < 224)
        c2 = utftext.charCodeAt(i + 1)
        string += String.fromCharCode(((c & 31) << 6) | (c2 & 63))
        i += 2
      else
        c2 = utftext.charCodeAt(i + 1)
        c3 = utftext.charCodeAt(i + 2)
        string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63))
        i += 3
    string

  # Return true x% of time based on argument.
  #
  # Example:
  #   runXpercent(10) => returns true 10% of the time
  runXpercent: (percent)->
    chance = Math.floor(Math.random() * 100)
    chance <= percent

  # deprecated functions starts
  _permissionMap: ->
    map =
      '---': 0
      '--x': 1
      '-w-': 2
      '-wx': 3
      'r--': 4
      'r-x': 5
      'rw-': 6
      'rwx': 7

  symbolsPermissionToOctal: (permissions) ->
    permissions = permissions.substr(1)

    user    = permissions.substr 0, 3
    group   = permissions.substr 3, 3
    other   = permissions.substr 6, 3
    octal   = '' + @_permissionMap()[user] + @_permissionMap()[group] + @_permissionMap()[other]

  # private member for tracking z-indexes
  zIndexContexts:{}

  # Get next highest Z-index
  getNextHighestZIndex:(context)->
   uniqid = context.data 'data-id'
   zIndexContexts[uniqid] if isNaN zIndexContexts[uniqid] then 0 else zIndexContexts[uniqid]++

  getAppIcon:(appManifest)->
    {authorNick, name, version, icns} = appManifest

    resourceRoot = "#{KD.appsUri}/#{authorNick}/#{name}/#{version}/"

    if appManifest.devMode # TODO: change url to https when vm urls are ready for it
      resourceRoot = "http://#{KD.getSingleton('vmController').defaultVm}/.applications/#{__utils.slugify name}/" 

    image  = if name is "Ace" then "icn-ace" else "default.app.thumb"
    thumb  = "#{KD.apiUri}/images/#{image}.png"

    for size in [64, 128, 160, 256, 512]
      if icns and icns[String size]
        thumb = "#{resourceRoot}/#{icns[String size]}"
        break

    img = new KDCustomHTMLView
      tagName     : "img"
      bind        : "error"
      error       : ->
        @getElement().setAttribute "src", "/images/default.app.thumb.png"
      attributes  :
        src       : thumb

    return img
  shortenUrl: (url, callback)->
    request = $.ajax "https://www.googleapis.com/urlshortener/v1/url",
      type        : "POST"
      contentType : "application/json"
      data        : JSON.stringify {longUrl: url}
      timeout     : 4000
      dataType    : "json"

    request.done (data)=>
      callback data?.id or url, data

    request.error ({status, statusText, responseText})->
      error "url shorten error, returing self as fallback.", status, statusText, responseText
      callback url

  # deprecated ends

###
//     Underscore.js 1.3.1
//     (c) 2009-2012 Jeremy Ashkenas, DocumentCloud Inc.
//     Underscore is freely distributable under the MIT license.
//     Portions of Underscore are inspired or borrowed from Prototype,
//     Oliver Steele's Functional, and John Resig's Micro-Templating.
//     For all details and documentation:
//     http://documentcloud.github.com/underscore
###

`
__utils.throttle = function(func, wait) {
  var context, args, timeout, throttling, more;
  var whenDone = __utils.debounce(function(){ more = throttling = false; }, wait);
  return function() {
    context = this; args = arguments;
    var later = function() {
      timeout = null;
      if (more) func.apply(context, args);
      whenDone();
    };
    if (!timeout) timeout = setTimeout(later, wait);
    if (throttling) {
      more = true;
    } else {
      func.apply(context, args);
    }
    whenDone();
    throttling = true;
  };
};

// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds.
__utils.debounce = function(func, wait) {
  var timeout;
  return function() {
    var context = this, args = arguments;
    var later = function() {
      timeout = null;
      func.apply(context, args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
};
`
