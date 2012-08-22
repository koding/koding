# JDiscussion
#  |_ JDiscussionReply*
#      |_ JComment*

class JDiscussionReply extends JComment
  {secure} = require 'bongo'
  @share()
  @set
  	relationships     :
  	  comment         : JComment
  	  participant     :
  	    targetType    : JAccount
  	    as            : ['author','commenter']
  	  likedBy         :
  	    targetType    : JAccount
  	    as            : 'like'
  	  repliesActivity :
  	    targetType    : CRepliesActivity
  	    as            : 'repliesActivity'
  	  tag             :
  	    targetType    : JTag
  	    as            : 'tag'
  	  follower        :
  	    as            : 'follower'
  	    targetType    : JAccount


# dont forget about garbage collection when a reply gets deleted

class JDiscussion extends JPost

  {secure} = require 'bongo'
  @share()

  @getActivityType =-> CDiscussionActivity
  @getAuthorType =-> JAccount

  @set
    sharedMethods : JPost.sharedMethods
    schema        : JPost.schema
    relationships     :
      comment         : JDiscussionReply
      participant     :
        targetType    : JAccount
        as            : ['author','commenter']
      likedBy         :
        targetType    : JAccount
        as            : 'like'
      repliesActivity :
        targetType    : CRepliesActivity
        as            : 'repliesActivity'
      tag             :
        targetType    : JTag
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : JAccount

  @create = secure (client, data, callback)->
    discussion =
      title 	: data.title
      body		: data.body
      meta		: data.meta
    JPost.create.call @, client, discussion, callback


  modify: secure (client, data, callback)->
    discussion =
      title   : data.title
      body    : data.body
      meta    : data.meta
    JPost::modify.call @, client, discussion, callback

  reply : secure (client, data, callback)->
    log "reply data is ", data
    discussion =
      body: data
    JReply::reply.call @, client, discussion, callback

class CDiscussionActivity extends CActivity
  @share()
  @set
    encapsulatedBy  : CActivity
    sharedMethods   : CActivity.sharedMethods
    schema          : CActivity.schema
    relationships   :
      subject       :
        targetType  : JDiscussion
        as          : 'content'
