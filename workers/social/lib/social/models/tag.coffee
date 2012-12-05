
jraphical = require 'jraphical'
CActivity = require './activity'
JAccount  = require './account'
KodingError = require '../error'

module.exports = class JTag extends jraphical.Module

  {Relationship} = jraphical

  {ObjectId, ObjectRef, Inflector, secure, daisy, race} = require 'bongo'

  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/protected'
  @trait __dirname, '../traits/slugifiable'

  @share()

  @set
    slugifyFrom     : 'title'
    slugTemplate    : 'Topics/#{slug}'
    permissions     : [
      'create tags'
      'edit tags'
      'delete tags'
      'edit own tags'
      'delete own tags'
    ]
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
        'one','on','some','create' #,'updateAllSlugs'
        'someWithRelationship','byRelevance'#,'markFollowing'
        'cursor','cursorWithRelationship','fetchMyFollowees'
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
    relationships   :->
      JAccount = require './account'
      creator       :
        targetType  : JAccount
      activity      :
        targetType  : CActivity
        as          : 'follower'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      content       :
        targetType  : [
          "JCodeSnip", "JApp", "JStatusUpdate", "JLink", "JTutorial"
          "JAccount", "JOpinion", "JDiscussion", "JCodeShare"

        ]
        as          : 'post'
      # content       :
      #   targetType  : [JCodeSnip, JAccount]
      #   as          : 'content'

  modify: secure (client, formData, callback)->
    {delegate} = client.connection
    if delegate.checkFlag ['super-admin', 'editor']
      modifiedTag = {slug: formData.slug.trim(), _id: $ne: @getId()}
      JTag.one modifiedTag, (err, tag)=>
        if tag
          callback new KodingError "Slug already exists!"
        else
          @update $set: formData, callback
    else
      callback new KodingError "Access denied"

  fetchContentTeasers:(options, selector, callback)->
    [callback, selector] = [selector, callback] unless callback

    selector or= {}
    selector['data.flags.isLowQuality'] = $ne: yes

    @fetchContents selector, options, (err, contents)->
      if err then callback err
      else if contents.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
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
            existingTagIds.push ObjectId tagRef.id
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
    {limit, blacklist, skip}  = options

    @some {
      title   : seed
      _id     :
        $nin  : blacklist
    },{
      skip
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
                    @emit 'TagIsDeleted', yes
                    callback null
                    contents.forEach (content)->
                      content.flushSnapshot tagId, (err)->
                        if err then console.log err

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
