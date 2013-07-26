JPost = require '../post'

module.exports = class JStatusUpdate extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'
  {permit} = require '../../group/permissionset'
  {once, extend} = require 'underscore'

  @trait __dirname, '../../../traits/grouprelated'

  @share()

  schema = extend {}, JPost.schema, {
    link :
      link_url   : String
      link_embed : Object
  }

  @set
    slugifyFrom       : 'body'
    sharedEvents      :
      instance        : [
        { name: 'TagsChanged' }
        { name: 'ReplyIsAdded' }
        { name: 'LikeIsAdded' }
        { name: 'updateInstance' }
      ]
      static          : []
    sharedMethods     :
      static          : ['create','one','fetchDataFromEmbedly','updateAllSlugs']
      instance        : [
        'reply','restComments','commentsByRange'
        'like','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments','checkIfLikedBefore'
      ]
    schema            : schema
    relationships     : JPost.relationships

  @getActivityType =-> require './statusactivity'

  @fetchDataFromEmbedly = (urls, options, callback)->

    urls = [urls]  unless Array.isArray urls

    Embedly = require "embedly"
    {apiKey} = KONFIG.embedly
    new Embedly key: apiKey, (err, api)->
      if err
        callback err
        return

      options = extend
        maxWidth: 150
      , options

      options.urls = urls
      api.extract options, (err, objs)->
        if err
          callback err
          return
        callback null, objs

  @create = secure (client, data, callback)->
    statusUpdate  =
      meta        : data.meta
      title       : data.title
      body        : data.body
      group       : data.group

    if data.link_url and data.link_embed
      statusUpdate.link =
        link_url   : data.link_url
        link_embed : data.link_embed

    JPost.create.call this, client, statusUpdate, callback

  modify: secure (client, data, callback)->
    statusUpdate =
      meta        : data.meta
      title       : data.title
      body        : data.body

    if data.link_url and data.link_embed
      statusUpdate.link =
        link_url   : data.link_url
        link_embed : data.link_embed

    JPost::modify.call this, client, statusUpdate, callback

  reply: permit 'reply to posts',
    success:(client, comment, callback)->
      JComment = require '../comment'
      JPost::reply.call this, client, JComment, comment, callback
