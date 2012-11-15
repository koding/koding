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

  getUniqueId:->
    "#{__utils.getRandomNumber(100000)}_#{Date.now()}"

  getRandomNumber :(range)->
    range = range or 1000000
    Math.floor Math.random()*range+1

  uniqueId : (prefix)->
    id = __utils.idCounter++
    if prefix? then "#{prefix}#{id}" else id

  getRandomRGB :()->
    "rgb(#{@getRandomNumber(255)},#{@getRandomNumber(255)},#{@getRandomNumber(255)})"

  getRandomHex : ->
    # hex = (Math.random()*0xFFFFFF<<0).toString(16)
    hex = (Math.random()*0x999999<<0).toString(16)
    while hex.length < 6
      hex += "0"
    "##{hex}"

  trimIllegalChars :(word)->

  curryCssClass:(obligatoryClass, optionalClass)-> obligatoryClass + if optionalClass then ' ' + optionalClass else ''


  getUrlParams:(tag)->
    tag ?= window.location.search
    hashParams = {};

    a = /\+/g  # Regex for replacing addition symbol with a space
    r = /([^&;=]+)=?([^&;]*)/g
    d = (s)->
      decodeURIComponent s.replace a, " "
    q = tag.substring 1

    while e = r.exec q
      hashParams[d e[1] ] = d e[2]

    hashParams

  capAndRemovePeriods:(path)->
    newPath = for arg in path.split "."
      arg.capitalize()
    newPath.join ""

  slugify:(title = "")->
    url = title
      .toLowerCase()                # change everything to lowercase
      .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
      .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens

  stripTags:(value)->
    value.replace /<(?:.|\n)*?>/gm, ''

  proxifyUrl:(url="")->
    if url is ""
      "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=="
    else
      "https://api.koding.com/1.0/image.php?url="+ encodeURIComponent(url)

  applyMarkdown: (text)->
    # problems with markdown so far:
    # - links are broken due to textexpansions (images too i guess)
    return null unless text

    marked.setOptions
      gfm: true
      pedantic: false
      sanitize: true
      highlight:(text,lang)->
        if hljs.LANGUAGES[lang]?
          hljs.highlight(lang,text).value
        else
          text

    text = Encoder.htmlDecode text

    text = marked text

  applyLineBreaks: (text)->
    return null unless text
    text.replace /\n/g, "<br />"

  applyTextExpansions: (text, shorten)->
    return null unless text
    # @expandWwwDotDomains @expandUrls @expandUsernames @expandTags text
    text = text.replace /&#10;/g, ' '
    text = __utils.putShowMore text if shorten
    @expandUrls @expandUsernames text
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
        u.link "#!/member/#{username}"
    # context-sensitive expansion
    else
      result = ""
      $(text).each (i,element)->
        if ($(element).parents(sensitiveTo).length is 0) and not ($(element).is sensitiveTo)
          if $(element).html()?
            replacedText =  $(element).html().replace /\B\@([\w\-]+)/gim, (u) ->
              username = u.replace "@", ""
              u.link "#!/member/#{username}"
            $(element).html replacedText
        result += $(element).get(0).outerHTML or "" # in case there is a text-only element
      result

  expandTags: (text) ->
    return null unless text
    text.replace /[#]+[A-Za-z0-9-_]+/g, (t) ->
      tag = t.replace "#", ""
      "<a href='#!/topic/#{tag}' class='ttag'><span>#{tag}</span></a>"

  expandUrls: (text) ->
    return null unless text

    urlGrabber = ///
      (\s|^)                              # Start after a whitespace or string[0]
      ([a-zA-Z]+\://)?                    # Captures any protocol (just not //)
      (\w+:\w+@)?                         # Username:Password
      ([a-zA-Z\d-]|[a-zA-Z\d-]\.)*        # Subdomains
      [a-zA-Z\d-]{2,}                     # Domain name
      \.                                  # THE DOT
      ([a-zA-Z]{2,4}(:\d+)?)              # Domain Extension with Port
      ([/\?\#][\S/]*)*                    # Some Request, greedy capture
      \b                                  # Last word boundary
      /?                                  # Optional trailing Slash
    ///g

    # used to be /(\s|^)([a-zA-Z]+\:\/\/)?(\w+:\w+@)?([a-zA-Z\d-]|[a-zA-Z\d-]\.)*[a-zA-Z\d-]{2,}\.([a-zA-Z]{2,4}(:\d+)?)([\/\?#][\S\/]*)*\b\/?/g
    text.replace urlGrabber, (url) ->
      originalUrl = url

      # remove protocol and trailing path
      visibleUrl = url.replace(/(ht|f)tp(s)?\:\/\//,"").replace(/\/.*/,"")

      checkForPostSlash = /.*(\/\/)+.*\/.+/.test originalUrl # test for // ... / ...

      if not /[A-Za-z]+:\/\//.test url

        # url has no protocol
        url = '//'+url

      "<a href='#{url}' data-original-url='#{originalUrl}' target='_blank' >#{visibleUrl}#{if checkForPostSlash then "/…" else ""}<span class='expanded-link'></span></a>"

  putShowMore: (text, l = 500)->
    shortenedText = __utils.shortenText text,
      minLength : l
      maxLength : l + Math.floor(l/10)
      suffix    : ' '

    text = if text.length > shortenedText.length
      morePart  = "<span class='collapsedtext hide'>"
      morePart += "<a href='#' class='more-link' title='Show more...'>···</a>"
      morePart += text.substr shortenedText.length
      morePart += "<a href='#' class='less-link' title='Show less...'>···</a>"
      morePart += "</span>"
      shortenedText + morePart
    else
      shortenedText

  shortenText:do ->
    tryToShorten = (longText, optimalBreak = ' ', suffix)->
      unless ~ longText.indexOf optimalBreak then no
      else
        longText.split(optimalBreak).slice(0, -1).join(optimalBreak) + (suffix ? optimalBreak)
    (longText, options={})->
      return unless longText
      minLength = options.minLength or 450
      maxLength = options.maxLength or 600
      suffix    = options.suffix     ? '...'

      longTextLength  = Encoder.htmlDecode(longText).length
      # longTextLength  = longText.length

      return longText if longTextLength < minLength or longTextLength < maxLength

      longText = Encoder.htmlDecode longText
      longText = longText.substr 0, maxLength

      # prefer to end the teaser at the end of a sentence (a period).
      # failing that prefer to end the teaser at the end of a word (a space).
      candidate = tryToShorten(longText, '. ', suffix) or tryToShorten longText, ' ', suffix

      if candidate?.length > minLength
        Encoder.htmlEncode candidate
        # candidate
      else
        Encoder.htmlEncode longText
        # longText

  getMonthOptions : ()->
    ((if i > 9 then { title : "#{i}", value : i} else { title : "0#{i}", value : i}) for i in [1..12])

  getYearOptions  : (min = 1900,max = Date::getFullYear())->
    ({ title : "#{i}", value : i} for i in [min..max])

  getFileExtension: (path) ->
    fileName = path or ''
    [name, extension...]  = fileName.split '.'
    extension = if extension.length is 0 then '' else extension[extension.length-1]

  getFileType: (extension)->

    fileType = "unknown"

    _extension_sets =
      code    : [
        "php", "pl", "py", "jsp", "asp", "htm","html", "phtml","shtml"
        "sh", "cgi", "htaccess","fcgi","wsgi","mvc","xml","sql","rhtml"
        "js","json","coffee"
        "css","styl","sass"
      ]
      text    : [
        "txt", "doc", "rtf", "csv", "docx", "pdf"
      ]
      archive : [
        "zip","gz","bz2","tar","7zip","rar","gzip","bzip2","arj","cab"
        "chm","cpio","deb","dmg","hfs","iso","lzh","lzma","msi","nsis"
        "rpm","udf","wim","xar","z","jar","ace","7z","uue"
      ]
      image   : [
        "png","gif","jpg","jpeg","bmp","svg","psd","qt","qtif","qif"
        "qti","tif","tiff","aif","aiff"
      ]
      video   : [
        "avi","mp4","h264","mov","mpg","ra","ram","mpg","mpeg","m4a"
        "3gp","wmv","flv","swf","wma","rm","rpm","rv"
      ]
      sound   : ["aac","au","gsm","mid","midi","snd","wav","3g2","mp3","asx","asf"]
      app     : ["kdapp"]


    for own type,set of _extension_sets
      for ext in set
        if extension is ext
          fileType = type

    return fileType

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

  getNameFromFullname :(fullname)->
    fullname.split(' ')[0]

  getParentPath :(path)->

    path = path.substr(0, path.length-1) if path.substr(-1) is "/"
    parentPath = path.split('/')
    parentPath.pop()
    return parentPath.join('/')

  removeBrokenSymlinksUnder:(path)->
    kiteController = KD.getSingleton('kiteController')
    escapeFilePath = FSHelper.escapeFilePath
    kiteController.run "stat #{escapeFilePath path}", (err)->
      if not err
        kiteController.run "find -L #{escapeFilePath path} -type l -delete", noop

  wait: (duration, fn) ->
    if "function" is typeof duration
      fn = duration
      duration = 0
    setTimeout fn, duration

  killWait:(id)-> clearTimeout id

  getCancellableCallback:(callback)->
    cancelled = no
    kallback = (rest...)->
      callback rest... unless cancelled
    kallback.cancel = -> cancelled = yes
    kallback

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
