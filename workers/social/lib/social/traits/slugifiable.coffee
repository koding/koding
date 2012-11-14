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

  generateUniqueSlug =(konstructor, slug, i, template, callback)->
    [callback, template] = [template, callback]  unless callback
    template or= '#{slug}'
    JName = require '../models/name'
    nameRE = RegExp "^#{template.replace '#\{slug\}', slug}(-\\d+)?$"
    selector = {name:nameRE}
    JName.someData selector, {name:1}, {sort:name:-1}, (err, cursor)->
      if err then callback err
      else cursor.nextObject (err, doc)->
        if err then callback err
        else
          nextCount =\
            if doc?
              {name} = doc
              lastCount = (name.match(/\-(\d)*$/) ? [])[1] ? 0
              "-#{++lastCount}"
            else ''
          nextName = "#{slug}#{nextCount}"
          nextNameFull = template.replace '#{slug}', nextName
          # selector = {name: nextName, constructorName, usedAsPath: 'slug'}
          JName.claim nextNameFull, konstructor, 'slug', (err, nameDoc)->
            if err?.code is 11000
              # we lost the race; try again
              generateUniqueSlug konstructor, slug, 0, template, callback
            else if err
              callback err
            else
              callback null, nextName

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
              postQueue.push ->
                post.updateSlug subclass.slugTemplate, (err, slug)->
                  callback err, slug
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
    {slugTemplate} = constructor
    {slugifyFrom} = constructor
    slug = slugify @[slugifyFrom]
    generateUniqueSlug constructor, slug, 0, slugTemplate, callback
