Date.create = -> new Date

Number::decimalToOctal = ->
  decimalToAnother = (n, radix) ->
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
    transponse s

  transponse = (s) ->
    n = s.length
    t = ''
    for i in [0...n]
      t = t + s.substring n - i - 1, n - i
    s = t
    s

  decimalToAnother @, 8


Function::swiss = (parent, names...)->
  for name in names
    @::[name] = parent::[name]
  @

class utils

  rules = [
    [/(matr|vert|ind)ix|ex$/gi  , '$1ices'  ]
    [/(m)an$/gi                 , '$1en'    ]
    [/(pe)rson$/gi              , '$1ople'  ]
    [/(child)$/gi               , '$1ren'   ]
    [/^(ox)$/gi                 , '$1en'    ]
    [/(ax|test)is$/gi           , '$1es'    ]
    [/(octop|vir)us$/gi         , '$1i'     ]
    [/(alias|status)$/gi        , '$1es'    ]
    [/(bu)s$/gi                 , '$1ses'   ]
    [/(buffal|tomat|potat)o$/gi , '$1oes'   ]
    [/([ti])um$/gi              , '$1a'     ]
    [/sis$/gi                   , 'ses'     ]
    [/(?:([^f])fe|([lr])f)$/gi  , '$1$2ves' ]
    [/(hive)$/gi                , '$1s'     ]
    [/([^aeiouy]|qu)y$/gi       , '$1ies'   ]
    [/(x|ch|ss|sh)$/gi          , '$1es'    ]
    [/([m|l])ouse$/gi           , '$1ice'   ]
    [/(quiz)$/gi                , '$1zes'   ]
    [/s$/gi                     , 's'       ]
    [/$/gi                      , 's'       ]
  ]

  uncountables = [
    'advice'
    'energy'
    'excretion'
    'digestion'
    'cooperation'
    'health'
    'labour'
    'machinery'
    'equipment'
    'information'
    'pollution'
    'sewage'
    'paprer'
    'money'
    'species'
    'series'
    'rain'
    'rice'
    'fish'
    'sheep'
    'moose'
    'deer'
    'news'
  ]

  regExpEscape:(text)->
      text.replace /[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&"

  getPathRegExp:(path)->
    # we coopt the express "Router" class (private API) for our own sinister purposes:
    {Route} = require 'express'
    new Route(null, path).regexp

  pluralize:(str) ->
    # original author: TJ Holowaychuk (extracted from Ext.js)
    # ported to coffeescript for inclusion here.
    unless ~ uncountables.indexOf str.toLowerCase()
      found = rules.filter (rule)->
        str.match rule[0]
      if found[0] then return str.replace found[0][0], found[0][1]
    return str

  capitalize:(str)->
    str[0].toUpperCase()+str.substr 1

  toCamelCase:(str)->
    str.replace /([\-][a-z])/g, ($1)-> $1.toUpperCase().replace /\-/g, ''

  toDashedString:(str)->
    str.replace /([A-Z])/g, ($1)-> '-'+$1.toLowerCase()

  toUnderscoredString:(str)->
    str.replace /([A-Z])/g, ($1)-> '_'+$1.toLowerCase()

  now: ->     Date.now()

  uniqid: ->  Date.now() + Math.floor Math.random()*110000

  randomBase62Hash:(length=8, ensureLength=yes)->
    # TODO: this function was ported from an answer on stackoverflow, and must
    #       perform wretchedly.  Also, it would seem likely that it is not
    #       guaranteed to be unique.
    hex = @md5 @makeSalt() + @uniqid()
    packedHex = pack 'H*', hex
    hash = Buffer(packedHex, 'base64').toString('ascii').replace /[^A-Za-z0-9]/g, ""

    if ensureLength
      length = Math.min 128, Math.max 4, length

      while hash.length < length
        hash += @randomBase62Hash(22, no) + ''
        hash #TODO: wtf is going on that this line is needed!? (but it is)

    hash.substr 0, length

  filename:(path) -> new RegExp("(/?([^\/]+))+").exec(path).pop()

  dirname:(path) -> "dirname_test"

  md5:(str) ->
    crypto.createHash('md5').update(str).digest 'hex'

  HOP:(obj,key) ->
    obj.hasOwnProperty key

  nicename:(name) ->
    name.toLowerCase().replace /[^a-z0-9]+/g, '-'

  makeTeaser:(long, options={})->
    return unless long

    minLength = options.minLength or 450
    maxLength = options.maxLength or 600

    return long if long < minLength or long < maxLength

    long = long.substr 0, maxLength

    # prefer to end the teaser at the end of a sentence (a period).
    # failing that prefer to end the teaser at the end of a word (a space).
    candidate = @tryToShorten(long, '.') or @tryToShorten long, ' ', '...'

    if candidate?.length > minLength
      candidate
    else
      long

  tryToShorten:(long, optimalBreak, suffix)->
    unless ~ long.indexOf optimalBreak then no
    else
      long.split(optimalBreak).slice(0, -1).join(optimalBreak) + (suffix ? optimalBreak)

  makeAuthKey:(plain=@makePlain())->
    # one-way encryption scheme:
    crypto.createHmac('sha1', @makeSalt()).update(plain).digest 'hex'

  makePlain:->
    Math.random()+'plain'

  makeSalt:->
    Math.round(Date.now() * Math.random()) + ''

  getNextGuestUsername:->
    'guest'

  traverseAndStripTags:(obj, allowed)->
    self = @
    traverse(obj).map (value, key)->
      if _.isString value
        @update self.stripTags value, allowed
  # A CS port of the phpjs strip_tags function
  stripTags:(input, allowed='') ->
    # make sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
    allowed = (allowed.toLowerCase().match(/<[a-z][a-z0-9]*>/g) or []).join ''
    tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi
     # we aren't going to filter out PHP tags, because we're not worried about compatibility with php:
    comments = /<!--[\s\S]*?-->/gi
    input.replace(comments, '')
         .replace tags, ($0, $1) -> if allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 then $0 else ''
(->
  Path = require 'path'

  Path.toDropbox = (path)->
    path = if path then @normalize path else ''
    path = path.substr 1 if path.length > 0 and path[0] is '/'
    path


  ###
  Path.makeSafe

  calls the provided function with the first filename that is
  similar to filepath, but that does not exist in the filesystem.
  generate new filename candidates by appending an underscore "_",
  and the next integer.
  ###
  Path.makeSafe = (filepath, callback)->
    _checkPath filepath, callback
  ###
  Path.hasExtname  p, ext

  returns true if the path "p" has the extension "ext".  More
  useful than the normal Path.extname, because it allows comparisons
  of extensions longer than one dot-unit.
  ###
  Path.hasExtname = (p, ext) ->
    units = ext.replace(/[^\.]/g, '').length # TODO: jsPerf this vs. alt. impl.: # ext.split('.').length - 1
    parts = p.split('/').pop().split '.'
    ext is '.'+parts[-units..].join '.'


  ###
  private helper _checkPath
  ###
  _checkPath = (filepath, callback, tries=0)->
    if tries > 0
      dirs = filepath.split '/'
      parts = dirs.pop().split '.'
      candidate = dirs.concat([parts[0] + '_' + tries].concat(parts[1..]).join '.').join '/'
    else
      candidate = filepath
    Path.exists candidate, (exists) ->
      if exists
        _checkPath filepath, callback, tries + 1
      else
        callback? candidate

)()

(->
  fs = require 'fs'
  fs.createPath = (path, callback) ->
    temp = path
    dirs = temp.split '/'
    run = (path) =>
      fs.mkdir path, 16877, (err) =>
        newFolder = dirs.shift()
        if newFolder
          run path + '/' + newFolder
        else
          callback()

    run dirs.shift()

)()

u = new utils