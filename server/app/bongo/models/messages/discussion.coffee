class JDiscussion extends JPost

  {secure} = require 'bongo'
  @share()

  @getActivityType =-> CDiscussionActivity
  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    # TODO: copying and pasting this for now...  We need an abstract interface "commentable" or something like that)
    relationships : JPost.relationships

  @create = secure (client, data, callback)->
    discussion =
      title 	: data.title
      body		: data.body
      meta		: data.meta
