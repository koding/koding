jraphical   = require 'jraphical'

module.exports = class JTutorialList extends jraphical.Module

  CActivity = require '../../activity'
  JAccount  = require '../../account'
  CBucket   = require '../../bucket'
  JTag      = require '../../tag'
  JTutorial = require '../tutorial'


  @trait __dirname, '../../../traits/filterable'       # brings only static methods
  @trait __dirname, '../../../traits/followable'
  @trait __dirname, '../../../traits/taggable'
  @trait __dirname, '../../../traits/likeable'

  {Inflector,JsPath,secure,daisy,ObjectId,ObjectRef,Base} = require 'bongo'
  {Relationship} = jraphical

  @share()

  @set

    indexes         :
      title         : 'ascending'

    sharedMethods   :
      instance      : [
        'update', 'follow', 'unfollow', 'delete', 'review',
        'like', 'checkIfLikedBefore', 'fetchLikedByes',
        'fetchFollowersWithRelationship', 'addItemById'
        'fetchFollowingWithRelationship', 'fetchCreator',
      ]
      static        : [
        "one","on","some","create","byRelevance",
        "someWithRelationship", "fetchForTutorialId"
      ]

    schema          :
      title         :
        type        : String
        set         : (value)-> value?.trim()
        required    : yes
      body          : String
      counts        :
        views       :
          type      : Number
          default   : 0
      thumbnails    : [Object]
      meta          : require "bongo/bundles/meta"
      # type          :
      #   type        : String
      #   enum        : ["Wrong type specified!",["web-app", "add-on", "server-stack", "framework"]]
      #   default     : "web-app"
      originId      : ObjectId
      originType    : String
      repliesCount  :
        type        : Number
        default     : 0

    relationships   :
      tutorial      :
        targetType  : JTutorial
        as          : "tutorial"
      creator       :
        targetType  : JAccount
        as          : "related"
      activity      :
        targetType  : CActivity
        as          : 'activity'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      likedBy       :
        targetType  : JAccount
        as          : 'like'
      participant   :
        targetType  : JAccount
        as          : ['author','viewer']
      tag           :
        targetType  : JTag
        as          : 'tag'

  @getAuthorType =-> JAccount

  {log} = console

  @create = secure (client, data, callback)->

    {connection:{delegate}} = client

    list = new JTutorialList
      title : data.title
      body  : data.body
      originId : delegate.getId()
      originType : delegate.constructor.name

    list.save (err)->
      if err
        log "Could not save TutorialList"
        callback err
      else
        list.addCreator delegate, (err)->
          if err
            log "Could not add creator to TutorialList"
            callback err
          else
            callback null, list

  addItemById : secure ({connection}, tutorialId, callback)->
    JTutorial.one
      _id: tutorialId
    , (err, tut)=>
      if tut
        @addTutorial tut, {as:"tutorial",respondWithCount:yes}, (err, docs, count)=>
          if err
            log err
            callback err
          else
            @update ($set: "repliesCount": count), (err)=>
              if err then callback err
              else
                callback null
      else
        log tutorialId+" Not found."

  @fetchForTutorialId : (tutorialId, callback)->
    Relationship.one
      sourceName:'JTutorialList'
      targetName:'JTutorial'
      targetId: tutorialId
      as: "tutorial"
    , (err, tutorialRelationship)=>
      if err
        callback err
      else
        if tutorialRelationship
          JTutorialList.one
            _id : tutorialRelationship.sourceId
          , (err, tutorialList)=>
            if err
              callback err
            else
              tutorialList.fetchList (err,list)=>
                if err
                  log err
                  callback err
                else
                  callback list
        else
          callback null

  fetchList:(callback)->
    @beginGraphlet()
      .edges
        query         :
          sourceName  : 'JTutorialList'
          targetName  : 'JTutorial'
          as          : 'tutorial'
      .nodes()
    .endGraphlet()
    .fetchRoot callback
