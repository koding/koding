JPost = require '../post'

module.exports = class JLink extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once} = require 'underscore'

  @share()

  @set
    sharedMethods     : JPost.sharedMethods
    schema            : JPost.schema
    relationships     : JPost.relationships

  @getActivityType =-> require './linkactivity'

  @create = secure (client, data, callback)->
    codeSnip =
      title       : data.title
      body        : data.body
      link_url    : data.link_url
      link_embed  : data.link_embed

      meta        : data.meta
    JPost.create.call @, client, codeSnip, callback

  reply: secure (client, comment, callback)->
    JComment = require '../comment'
    JPost::reply.call @, client, JComment, comment, callback
