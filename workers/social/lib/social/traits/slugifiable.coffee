
module.exports = class Slugifiable

  {dash, daisy, secure} = require 'bongo'

  KodingError = require '../error'

  slugify =(str='')->
    slug = str
      .trim()                       # trim leading and trailing ws
      .toLowerCase()                # change everything to lowercase
      .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
      .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens
      .substr 0, 256                # limit these to 256-chars (pre-suffix), for sanity

  getNextCount =(name)->            # the name is something like `name: "foo-bar-42"`
    count = name
      .map ({name})->
        [d] = (/\d+$/.exec name) ? [0]; +d # take the digit part, cast it to a number.
      .sort (a, b)->
        a - b
      .pop()                        # the last item is the highest, pop from the tmp array
    if isNaN count then ''          # show empty string instead of zero...
    else "-#{count + 1}"            # otherwise, try the next integer.

  @suggestUniqueSlug = secure (client, slug, i, callback)->
    [client, slug, callback, i] = [client, slug, i, callback] unless callback
    i ?= 0
    JAccount = require '../models/account'
    {delegate} = client.connection
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied.'
    unless slug.length then callback null, ''
    else
      JName = require '../models/name'
      suggestedSlug = if i is 0 then slug else "#{slug}-#{i}"
      selector = name: suggestedSlug
      JName.one selector, (err, name)=>
        if err then callback err
        else
          if name
            @suggestUniqueSlug client, slug, i+1, callback
          else
            callback null, suggestedSlug

  claimUniqueSlug =(ctx, konstructor, slug, callback)->
    JName = require '../models/name'
    {collectionName} = konstructor.getCollection()
    nextName = {
      slug            : slug
      constructorName : konstructor.name
      usedAsPath      : konstructor.usedAsPath ? 'slug'
      group           : ctx.group
      collectionName
    }
    nextNameFull = nextName.slug
    JName.claim nextNameFull, [nextName], konstructor, 'slug', (err, nameDoc)->
      if err then callback err
      else
        callback null, nextName

  generateUniqueSlug =(ctx, konstructor, slug, i, template, callback)->
    [callback, template] = [template, callback]  unless callback
    template or= '#{slug}'
    JName = require '../models/name'
    template = template.call ctx  if 'function' is typeof template
    selector = name: RegExp "^#{template.replace '#\{slug\}', slug}(-\\d+)?$"
    JName.someData selector, {name:1}, {sort:name:-1}, (err, cursor)->
      if err then callback err
      else cursor.toArray (err, names)->
        if err then callback err
        else
          nextCount = getNextCount names
          {collectionName} = konstructor.getCollection()
          nextName = {
            slug            : "#{slug}#{nextCount}"
            constructorName : konstructor.name
            usedAsPath      : konstructor.usedAsPath ? 'slug'
            group           : ctx.group
            collectionName
          }
          nextNameFull = template.replace '#{slug}', nextName.slug
          JName.claim nextNameFull, [nextName], konstructor, 'slug', (err, nameDoc)->
            if err?.code is 11000
              console.log err
              # we lost the race; try again
              generateUniqueSlug ctx, konstructor, slug, 0, template, callback
            else if err
              callback err
            else
              callback null, nextName
    
  # @updateAllSlugsResourceIntensively = (options, callback)->
  #   [callback, options] = [options, callback] unless callback
  #   options ?= {}
  #   selector = if options.force then {} else {slug_: $exists: no}
  #   subclasses = @encapsulatedSubclasses ? [@]
  #   JName = require '../models/name'
  #   JName.someData {},{name:1,_id:1,constructorName:1},{},(err,names)->
  #     console.log "namesArr in"
  #     names.toArray (err,namesArr)->
  #       contentTypeQueue = subclasses.map (subclass)->->
  #         console.log "2"  
  #         subclass.someData {},{title:1,_id:1},{limit:1000},(err,cursor)->
  #           console.log "3"
  #           if err
  #             callback err
  #           else
  #             cursor.toArray (err,arr)->
  #               if err
  #                 callback err
  #               else
  #                 a.contructorName = subclass.name for a in arr
  #                 console.log "4"
  #                 console.log "arr ->",arr,"namesArr -> ",namesArr
  #                 callback null #,arr,namesArr
  #         
  #       dash contentTypeQueue, callback

  @updateSlugsByBatch =(batchSize, konstructors)->
    konstructors = [konstructors]  unless Array.isArray konstructors
    konstructors.forEach (konstructor)->
      counter = 0
      konstructor.updateAllSlugs {batchSize}, (err,slug)->
        console.log slug
        if ++counter is batchSize
          process.nextTick -> updateSlugsByBatch batchSize, konstructor

  @updateAllSlugs = (options, callback)->
    [callback, options] = [options, callback] unless callback
    options ?= {}
    selector = if options.force then {} else {slug_: $exists: no}
    subclasses = @encapsulatedSubclasses ? [@]
    contentTypeQueue = subclasses.map (subclass)->->
      subclass.cursor selector, options, (err, cursor)->
        if err then console.error err #contentTypeQueue.next err
        else
          postQueue = []
          cursor.each (err, post)->
            if err then console.error err#postQueue.next err
            else if post?
              postQueue.push ->
                post.updateSlug (err, slug)->
                  callback null, slug
                  postQueue.next()
            else
              daisy postQueue, -> contentTypeQueue.fin()
    dash contentTypeQueue, callback

  updateSlug:(callback)->
    @createSlug (err, slug)=>
      if err then callback err
      else @update $set:{slug, slug_:slug}, (err)->
        callback err, unless err then slug

  createSlug:(callback)->
    {constructor} = this
    {slugTemplate, slugifyFrom} = constructor
    slug = slugify @[slugifyFrom]
    generateUniqueSlug this, constructor, slug, 0, slugTemplate, callback

  useSlug:(slug, callback)->
    {constructor} = this
    claimUniqueSlug this, constructor, slug, callback