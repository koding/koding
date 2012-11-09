module.exports = class Sluggifiable

  generateSlug =(str)->
    slug = str
      .toLowerCase()                # change everything to lowercase
      .replace(/^\s+|\s+$/g, "")    # trim leading and trailing spaces
      .replace(/[_|\s]+/g, "-")     # change all spaces and underscores to a hyphen
      .replace(/[^a-z0-9-]+/g, "")  # remove all non-alphanumeric characters except the hyphen
      .replace(/[-]+/g, "-")        # replace multiple instances of the hyphen with a single instance
      .replace(/^-+|-+$/g, "")      # trim leading and trailing hyphens

  generateUniqueSlug =(constructor, slug, i, callback)->
    [callback, i] = [i, callback] unless callback
    i ?= 0
    candidate = "#{slug}#{i or ''}"
    constructor.count slug: candidate, (err, count)->
      if err then callback err
      else if count > 0
        generateUniqueSlug constructor, slug, ++i, callback
      else
        callback null, candidate

  createSlug:(callback)->
    {constructor} = this
    {slugifyFrom} = constructor
    slug = generateSlug @[slugifyFrom]
    generateUniqueSlug constructor, slug, callback
