module.exports = class Taggable

  async                 = require 'async'
  { Relationship }      = require 'jraphical'
  { ObjectRef, secure } = require 'bongo'

  getTaggedContentRole  : -> @constructor.taggedContentRole or 'tagged'
  getTagRole            : -> @constructor.tagRole           or 'tag'

  addTags: secure (client, tags, options, callback) ->
    JTag = require '../models/tag'
    [callback, options] = [options, callback] unless callback
    options or= { silent: no }
    taggedContentRole = @getTaggedContentRole()
    tagCount = 0
    taggedCount = 0

    { delegate } = client.connection
    exempt = delegate.isExempt

    @removeAllTags client, { silent: tags.length > 0 }, (err) =>
      if err then callback err
      else unless tags.length then callback null
      else
        JTag.handleFreetags client, tags, (err, tag) =>
          return callback err  if err

          async.series [

            (next) =>
              @addTag tag, next

            (next) =>
              incCount = {}
              incCount["counts.#{taggedContentRole}"] = taggedCount
              tag.update { $set: incCount }, (err) =>
                return next err  if err
                if ++tagCount is tags.length
                  @emit 'TagsChanged', tags unless options.silent
                next()

          ], callback

  removeAllTags: secure (client, options, callback) ->
    [callback, options] = [options, callback] unless callback
    options or= { silent: no }
    Relationship.remove { $or: [{
        as        : @getTaggedContentRole()
        targetId  : @getId()
      }, {
        as        : @getTagRole()
        sourceId  : @getId()
      }]
    }, (err) =>
      if err then callback err
      else
        @emit 'TagsChanged', [] unless options.silent
        callback null
