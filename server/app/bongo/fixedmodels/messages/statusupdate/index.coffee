JPost = require '../post'

module.exports = class JStatusUpdate extends JPost
  {secure} = require 'bongo'
  {Relationship} = require 'jraphical'

  {once} = require 'underscore'

  @share()

  @set
    sharedMethods     : JPost.sharedMethods
    schema            : JPost.schema
    relationships     : JPost.relationships

  @getActivityType =-> CStatusActivity

  reply: secure (client, comment, callback)->
    JPost::reply.call @, client, JComment, comment, callback