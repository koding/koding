# utils singleton
# -------------------------
#
# -------------------------
__utils =

  idCounter : 0

  formatPlural:(count, noun)->
    "#{count or 0} #{if count is 1 then noun else Inflector.pluralize noun}"

  selectText:(element)->
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

  applyMarkdown: (text)->
    # problems with markdown so far:
    # - links are broken due to textexpansions (images too i guess)
    return null unless text

    marked.setOptions
      gfm: true
      pedantic: false
      sanitize: true
      highlight:(text)->
        # log "highlight callback called"
        # if hljs?
        #   requirejs (['js/highlightjs/highlight.js']), ->
        #     requirejs (["highlightjs/languages/javascript"]), ->
        #       try
        #         hljs.compileModes()
        #         _text = hljs.highlightAuto text
        #         log "hl",_text,text
        #         return _text.value
        #       catch err
        #         log "Error applying highlightjs syntax", err
        # else
        #   log "hljs not found"
          return text

    text = Encoder.htmlDecode text

    text = marked text

  applyLineBreaks: (text)->
    return null unless text
    text.replace /\n/g, "<br />"

  applyTextExpansions: (text)->
    return null unless text
    # @expandWwwDotDomains @expandUrls @expandUsernames @expandTags text
    @expandWwwDotDomains @expandUrls @expandUsernames text

  expandWwwDotDomains: (text) ->
    return null unless text
    text.replace /(^|\s)(www\.[A-Za-z0-9-_]+.[A-Za-z0-9-_:%&\?\/.=]+)/g, (_, whitespace, www) ->
      "#{whitespace}<a href='http://#{www}' target='_blank'>#{www}</a>"

  expandUsernames: (text) ->
    return null unless text
    text.replace /\B\@([\w\-]+)/gim, (u) ->
      username = u.replace "@", ""
      u.link "#!/member/#{username}"

  expandTags: (text) ->
    return null unless text
    text.replace /[#]+[A-Za-z0-9-_]+/g, (t) ->
      tag = t.replace "#", ""
      "<a href='#!/topic/#{tag}' class='ttag'><span>#{tag}</span></a>"

  expandUrls: (text) ->
    return null unless text
    text.replace /[A-Za-z]+:\/\/[A-Za-z0-9-_]+\.[A-Za-z0-9-_:%&\?\/.=]+/g, (url) ->
      "<a href='#{url}' target='_blank'>#{url}</a>"

  shortenText:do ->
    tryToShorten = (longText, optimalBreak, suffix)->
      unless ~ longText.indexOf optimalBreak then no
      else
        longText.split(optimalBreak).slice(0, -1).join(optimalBreak) + (suffix ? optimalBreak)
    (longText, options={})->
      return unless longText
      minLength = options.minLength or 450
      maxLength = options.maxLength or 600

      return longText if longText < minLength or longText < maxLength

      longText = longText.substr 0, maxLength

      # prefer to end the teaser at the end of a sentence (a period).
      # failing that prefer to end the teaser at the end of a word (a space).
      candidate = tryToShorten(longText, '.') or tryToShorten longText, ' ', '...'

      if candidate?.length > minLength
        candidate
      else
        longText

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
