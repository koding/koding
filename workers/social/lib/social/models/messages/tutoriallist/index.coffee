JPost = require '../post'

module.exports = class JTutorialList extends JPost

  # @mixin Followable
  # @::mixin Followable::
  # @::mixin Taggable::
  # @::mixin Notifying::
  # @mixin Flaggable
  # @::mixin Flaggable::
  # @::mixin Likeable::

  {Base,ObjectId,ObjectRef,secure,dash,daisy} = require 'bongo'
  {Relationship} = require 'jraphical'

  {log} = console

  {once, extend} = require 'underscore'

  @share()

  schema = extend {}, JPost.schema, { items : Array }

  @getActivityType =-> require './tutoriallistactivity'

  @getAuthorType =-> require '../../account'

  @getFlagRole =-> ['sender', 'recipient']
  @set
    emitFollowingActivities: yes
    taggedContentRole : 'post'
    tagRole           : 'tag'
    sharedMethods     :
      static          : ['create','one']
      instance        : [
        'on','reply','restComments','commentsByRange'
        'like','checkIfLikedBefore','fetchLikedByes','mark','unmark','fetchTags'
        'delete','modify','fetchRelativeComments'
        'updateTeaser'
      ]
    schema            : schema
    relationships     :
      tutorial         :
        targetType    : "JTutorial"
        as            : 'tutorial'
      participant     :
        targetType    : "JAccount"
        as            : ['author','commenter']
      likedBy         :
        targetType    : "JAccount"
        as            : 'like'
      repliesActivity :
        targetType    : "CRepliesActivity"
        as            : 'repliesActivity'
      tag             :
        targetType    : "JTag"
        as            : 'tag'
      follower        :
        as            : 'follower'
        targetType    : "JAccount"

  @create = secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
      items        : data.items
    JPost.create.call @, client, discussion, callback

  modify: secure (client, data, callback)->
    discussion =
      title       : data.title
      body        : data.body
      meta        : data.meta
      items        : data.items
    JPost::modify.call @, client, discussion, callback

  fetchTeaser:(callback)->
    @beginGraphlet()
      .edges
        query         :
          sourceName  : 'JTutorialList'
          targetName  : 'JTag'
          as          : 'tag'
        limit         : 5
      .and()
      .edges
        query         :
          targetName  : 'JTutorial'
          as          : 'tutorial'
          'data.deletedAt':
            $exists   : no
          'data.flags.isLowQuality':
            $ne       : yes
        limit         : 5
        sort          :
          timestamp   : 1
      .nodes()
    .endGraphlet()
    .fetchRoot callback