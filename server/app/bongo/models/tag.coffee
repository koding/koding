class JTag extends Followable

  {Relationship} = jraphical

  @mixin Filterable         # brings only static methods
  @::mixin Taggable::

  # @mixin Followable       # brings only static methods
  # @::mixin Followable::   # brings only prototype methods
  # @::mixin Filterable::   # brings only prototype methods

  {ObjectRef,Inflector,secure,daisy} = bongo

  @share()

  @set
    emitFollowingActivities : yes # create buckets for follower / followees
    indexes         :
      slug          : 'unique'
    sharedMethods   :
      instance      : [
        'modify','follow', 'unfollow', 'fetchFollowersWithRelationship'
        'fetchFollowingWithRelationship','fetchContents','fetchContentTeasers',
        'delete'
        ]
      static        : [
        "one","on","some","all","create",
        'someWithRelationship','byRelevance'#,'markFollowing'
        ]
    schema          :
      title         :
        type        : String
        set         : (value)-> value.trim()
        required    : yes
      slug          :
        type        : String
        default     : (value)-> Inflector.slugify @title.trim().toLowerCase()
        validate    : [
          'invalid tag name'
          (value)->
            0 < value.length <= 256 and /^(?:\d|\w|\-|\+|\#|\.| [^ ])*$/.test(value)
        ]
      body          : String
      counts        :
        followers   :
          type      : Number
          default   : 0
        following   :
          type      : Number
          default   : 0
        tagged      :
          type      : Number
          default   : 0
      synonyms      : [String]
      # owner         : ObjectId
    relationships   : ->
      creator       : JAccount
      activity      :
        targetType  : CActivity
        as          : 'follower'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      content       :
        targetType  : [JCodeSnip, JApp, JStatusUpdate, JAccount]
        as          : 'post'
      # content       :
      #   targetType  : [JCodeSnip, JAccount]
      #   as          : 'content'
  modify: secure (client, formData, callback)->
    callback arguments

  fetchContentTeasers:->
    [args..., callback] = arguments
    @fetchContents args..., (err, contents)->
      if err then callback err
      else
        teasers = []
        collectTeasers = bongo.race (i, root, fin)->
          root.fetchTeaser (err, teaser)->
            if err then callback err
            else
              teasers[i] = teaser
              fin()
        , -> callback null, teasers
        collectTeasers node for node in contents


  @handleFreetags = secure (client, tagRefs, callbackForEach=->)->
    existingTagIds = []
    daisy queue = [
      ->
        fin =(i)-> if i is tagRefs.length-1 then queue.next()
        tagRefs.forEach (tagRef, i)->
          if tagRef?.$suggest?
            newTag = {title: tagRef.$suggest.trim()}
            JTag.one newTag, (err, tag)->
              if err
                callbackForEach err
              else if tag?
                callbackForEach null, tag
                fin i
              else
                JTag.create client, newTag, (err, tag)->
                  if err
                    callbackForEach err
                  else
                    tagRefs[i] = ObjectRef(tag).data
                    callbackForEach null, tag
                    fin i
          else
            existingTagIds.push bongo.ObjectId tagRef.id
            fin i
      ->
        JTag.all (_id: $in: existingTagIds), (err, existingTags)->
          if err
            callbackForEach err
          else
            callbackForEach null, tag for tag in existingTags
    ]

  @create = secure (client, data, callback)->
    {delegate} = client.connection
    tag = new @ data
    tag.save (err)->
      if err
        callback err
      else
        tag.addCreator delegate, (err)->
          if err
            callback err
          else
            callback null, tag

  @findSuggestions = (seed, options, callback)->
    {limit, blacklist}  = options

    @some {
      title   : seed
      _id     :
        $nin  : blacklist
    },{
      limit
      sort    : 'title' : 1
    }, callback

  delete: secure (client, callback)->
    {delegate} = client.connection
    delegate.fetchRole client, (err, role)=>
      if err
        callback err
      else unless role is 'super-admin'
        callback new KodingError 'Access denied!'
      else
        tagId = @getId()
        @fetchContents (err, contents)=>
          if err
            callback err
          else
            Relationship.remove {
              $or: [{
                targetId  : tagId
                as        : 'tag'
              },{
                sourceId  : tagId
                as        : 'post'
              }]
            }, (err)=>
              if err
                callback err
              else
                @remove (err)=>
                  if err
                    callback err
                  else
                    @emit 'TagIsDeleted', 1
                    callback null
                    contents.forEach (content)->
                      content.flushSnapshot tagId, (err)->
                        if err then console.log err
  # save: secure (client,callback)->
  #   tag = @
  #   account = client.connection.delegate
  #   if account instanceof JGuest
  #     callback new Error "guest cant add topic"
  #   else
  #     bongo.Model::save.call @, (err)->
  #       if err
  #         callback err
  #       else
  #         callback null,tag
  #
  # update: bongo.secure (client,callback)->
  # remove: bongo.secure (client,callback)->


#
# class JLicense extends JTag
#
#   @share()
#
#   @set
#     encapsulatedBy  : JTag
#     schema          : JTag.schema
#
# class JSkill extends JTag
#
#   @share()
#
#   @set
#     encapsulatedBy  : JTag
#     schema          : JTag.schema
#
#
