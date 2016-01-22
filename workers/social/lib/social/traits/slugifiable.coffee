module.exports = class Slugifiable

  async      = require 'async'
  { secure } = require 'bongo'

  KodingError = require '../error'

  stopWordRegExp = do ->
    stopWords = [
        'a', 'has', 'such', 'accordance', 'have', 'suitable', 'according', 'having', 'than',
        'all', 'herein', 'that', 'also', 'however', 'the', 'an', 'if', 'their',
        'and', 'in', 'then', 'another', 'into', 'there', 'are', 'invention', 'thereby',
        'as', 'is', 'therefore', 'at', 'it', 'thereof', 'be', 'its', 'thereto',
        'because', 'means', 'these', 'been', 'not', 'they', 'being', 'now', 'this',
        'by', 'of', 'those', 'claim', 'on', 'thus', 'comprises', 'onto', 'to',
        'corresponding', 'or', 'use', 'could', 'other', 'various', 'described', 'particularly', 'was',
        'desired', 'preferably', 'were', 'do', 'preferred', 'what',
        'does', 'present', 'when', 'each', 'provide', 'where', 'embodiment', 'provided', 'whereby',
        'fig', 'provides', 'wherein', 'figs', 'relatively', 'which',
        'for', 'respectively', 'while', 'from', 'said', 'who', 'further', 'should', 'will',
        'generally', 'since', 'with', 'had', 'some', 'would',
    ]

    return /// \b(#{stopWords.join('|')})\b ///gi

  slugify = (str = '') ->
    maxLen = 80
    slug = str
      .trim()                            # trim leading and trailing ws
      .toLowerCase()                     # change everything to lowercase
      .replace(/^\s+|\s+$/g, '')         # trim leading and trailing spaces
      .replace(/\|.+?\|/g, '')           # remove tokens
      .replace(/[_|\s]+/g, '-')          # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, '')       # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, '-')             # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, '')           # trim leading and trailing hyphens

    # if slug length is bigger than maxLen remove stopwords from it
    if slug.length > maxLen
      slug = slug
      .replace(stopWordRegExp, '')
      .replace(/[-]+/g, '-')             # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, '')           # trim leading and trailing hyphens

      #return slug if it gets shorter than the maxLen
      return slug if slug.length <= maxLen

      characterAtMaxLen = slug.charAt(maxLen)
      hyphen = '-'

      # if the last character is hyphen then delete it and return
      return slug.substr(0, maxLen) if characterAtMaxLen is hyphen

      # go back 8 character and go forward 6 character from maxLen limit
      # if we have any hyphen there(if there is more than 1 get the last one), truncate to that length
      slugPart = slug.slice(maxLen - 8, maxLen + 6).lastIndexOf(hyphen)
      # if no hyphen found within that range then truncate to maxLen
      index = if slugPart < 0 then maxLen else maxLen - 8 + slugPart
      # finalize the length operations
      slug = slug.substr(0, index)
      # trim leading and trailing hyphens
      slug.replace(/^-+|-+$/g, '')

    return slug

  @slugify = slugify

  getNextCount = (name) ->            # the name is something like `name: "foo-bar-42"`
    count = name
      .map ({ name }) ->
        [d] = (/\d+$/.exec name) ? [0]; +d # take the digit part, cast it to a number.
      .sort (a, b) ->
        a - b
      .pop()                        # the last item is the highest, pop from the tmp array
    if isNaN count then ''          # show empty string instead of zero...
    else "-#{count + 1}"            # otherwise, try the next integer.

  @suggestUniqueSlug = secure (client, slug, i, callback) ->
    [client, slug, callback, i] = [client, slug, i, callback] unless callback
    i ?= 0
    JAccount = require '../models/account'
    { delegate } = client.connection
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied'
    unless slug.length then callback null, ''
    else
      JName = require '../models/name'
      suggestedSlug = if i is 0 then slug else "#{slug}-#{i}"
      selector = { name: suggestedSlug }
      JName.one selector, (err, name) =>
        if err then callback err
        else
          if name
            @suggestUniqueSlug client, slug, i + 1, callback
          else
            callback null, suggestedSlug

  claimUniqueSlug = (ctx, konstructor, slug, callback) ->
    JName = require '../models/name'
    { collectionName } = konstructor.getCollection()
    nextName = {
      slug            : slug
      constructorName : konstructor.name
      usedAsPath      : konstructor.usedAsPath ? 'slug'
      group           : ctx.group
      collectionName
    }
    nextNameFull = nextName.slug
    JName.claim nextNameFull, [nextName], konstructor, 'slug', (err, nameDoc) ->
      if err then callback err
      else
        callback null, nextName

  generateUniqueSlug = (ctx, konstructor, slug, i, template, callback) ->
    [callback, template] = [template, callback]  unless callback
    template or= '#{slug}'
    JName = require '../models/name'
    template = template.call ctx  if 'function' is typeof template
    selector = { name: RegExp "^#{template.replace '#\{slug\}', slug}(-\\d+)?$" }
    JName.someData selector, { name:1 }, { sort:{ name:-1 } }, (err, cursor) ->
      if err then callback err
      else cursor.toArray (err, names) ->
        if err then callback err
        else
          nextCount = getNextCount names
          { collectionName } = konstructor.getCollection()
          nextName = {
            slug            : "#{slug}#{nextCount}"
            constructorName : konstructor.name
            usedAsPath      : konstructor.usedAsPath ? 'slug'
            group           : ctx.group
            collectionName
          }
          nextNameFull = template.replace '#{slug}', nextName.slug
          JName.claim nextNameFull, [nextName], konstructor, 'slug', (err, nameDoc) ->
            if err?.code is 11000
              console.log err
              # we lost the race; try again
              generateUniqueSlug ctx, konstructor, slug, 0, template, callback
            else if err
              callback err
            else
              callback null, nextName

  updateSlug:(callback) ->
    @createSlug (err, slug) =>
      if err then callback err
      else @update { $set:{ slug:slug.slug, slug_:slug.slug } }, (err) ->
        callback err, unless err then slug

  createSlug:(callback) ->
    { constructor } = this
    { slugTemplate, slugifyFrom } = constructor
    slug = slugify @[slugifyFrom]
    generateUniqueSlug this, constructor, slug, 0, slugTemplate, callback

  useSlug:(slug, callback) ->
    { constructor } = this
    claimUniqueSlug this, constructor, slug, callback
