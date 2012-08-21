# JDiscussion
#  |_ JDiscussionReply*
#      |_ JComment*

class JDiscussionReply extends JComment
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
# give it the relationships of a post while being a comment
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
    log discussion


