module.exports = class Slugifiable

  {dash, daisy} = require 'bongo'

  slugify =(str)->
    slug = str
      .toLowerCase()                # change everything to lowercase
      .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
      .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens
      .substr 0, 256                # limit these to 256-chars (pre-suffix), for sanity

  generateUniqueSlug =(constructor, slug, i, callback)->
    candidate = "#{slug}#{i or ''}"
    constructor.count slug: candidate, (err, count)->
      if err then callback err
      else if count > 0
        generateUniqueSlug constructor, slug, ++i, callback
      else
        callback null, candidate

  @updateAllSlugs = (options, callback)->
    [callback, options] = [options, callback] unless callback
    options ?= {}
    selector = if options.force then {} else {slug_: $exists: no}
    subclasses = @encapsulatedSubclasses ? [@]
    contentTypeQueue = subclasses.map (subclass)->->
      subclass.cursor selector, options, (err, cursor)->
        if err then contentTypeQueue.next err
        else
          postQueue = []
          cursor.each (err, post)->
            if err then postQueue.next err
            else if post?
              postQueue.push -> post.updateSlug (err, slug)->
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
    {slugifyFrom} = constructor
    slug = slugify @[slugifyFrom]
    generateUniqueSlug constructor, slug, 0, callback
