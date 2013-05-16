
jraphical = require 'jraphical'
CActivity = require './activity'
KodingError = require '../error'

module.exports = class JTag extends jraphical.Module

  {Relationship} = jraphical

  {ObjectId, ObjectRef, Inflector, secure, daisy, race} = require 'bongo'

  Validators  = require './group/validators'
  {permit}    = require './group/permissionset'

  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/protected'
  @trait __dirname, '../traits/slugifiable'
  @trait __dirname, '../traits/grouprelated'

  @share()

  @set
    softDelete      : yes
    slugifyFrom     : 'title'
    slugTemplate    : ->
      """
      #{if @group is 'koding' then '' else "#{@group}/"}Topics/\#{slug}
      """
    permissions     :
      'create tags'           : ['member', 'moderator']
      'freetag content'       : ['member', 'moderator']
      'browse content by tag' : ['member', 'moderator']
      'edit tags'             : ['moderator']
      'delete tags'           : ['moderator']
      'edit own tags'         : ['moderator']
      'delete own tags'       : ['moderator']
    emitFollowingActivities : yes # create buckets for follower / followees
    indexes         :
      # slug          : 'unique'
      title         : 'sparse'
      # group         : 'sparse'
    sharedEvents    :
      instance      : [
        { name: 'updateInstance' }
      ]
    sharedMethods   :
      instance      : [
        'modify','follow', 'unfollow', 'fetchFollowersWithRelationship'
        'fetchFollowingWithRelationship','fetchContents','fetchContentTeasers',
        'delete'
        ]
      static        : [
        'one','on','some','create', 'count' #,'updateAllSlugs'
        'someWithRelationship','byRelevance'#,'markFollowing'
        'cursor','cursorWithRelationship','fetchMyFollowees','each'
        ]
    schema          :
      title         :
        type        : String
        set         : (value)-> value.trim()
        required    : yes
      slug          :
        type        : String
        default     : (value)-> Inflector.slugify @title.toLowerCase()
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
      group         : String
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
          "JAccount", "JOpinion", "JDiscussion", "JCodeShare", 'JBlogPost'

        ]
        as          : 'post'

  modify: permit
    advanced: [
      { permission: 'edit own tags', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success: (client, formData, callback)->
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

  @handleFreetags = permit 'freetag content',
    success: (client, tagRefs, callbackForEach=->)->
      existingTagIds = []
      daisy queue = [
        ->
          fin =(i)-> if i is tagRefs.length-1 then queue.next()
          tagRefs.forEach (tagRef, i)->
            if tagRef?.$suggest?
              {group} = client.context
              newTag = {title: tagRef.$suggest.trim()}
              newTag.group = group if group isnt 'koding'
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

  @create = permit 'create tags',
    success: (client, data, callback)->
      {delegate} = client.connection
      {group} = client.context
      tag = new this data
      tag.group = group
      tag.createSlug (err, slug)->
        if err then callback err
        else
          tag.slug = slug.slug
          tag.slug_ = slug.slug
          tag.save (err)->
            if err
              callback err
            else
              tag.addCreator delegate, (err)->
                if err
                  callback err
                else
                  callback null, tag

  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip} = options
    {group} = client.context
    @some {
        group
        title   : seed
        _id     :
          $nin  : blacklist
      },{
        skip
        limit
        sort    : 'title' : 1
      }, callback

  delete: permit
    advanced: [
      { permission: 'delete own tags', validateWith: Validators.own }
      { permission: 'delete tags' }
    ]
    success: (client, callback)->
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

  makeGroupSelector =(group)->
    if Array.isArray group then $in: group else group

  @one$ = permit 'browse content by tag',
    success:(client, uniqueSelector, options, callback)->
      uniqueSelector.group = makeGroupSelector client.context.group
      @one uniqueSelector, options, callback

  @some$ = permit 'browse content by tag',
    success:(client, selector, options, callback)->
      selector.group = makeGroupSelector client.context.group
      @some selector, options, callback

  @count$ = permit 'browse content by tag',
    success:(client, selector, callback)->
      [callback, selector] = [selector, callback]  unless callback
      selector ?= {}
      selector.group = makeGroupSelector client.context.group
      @count selector, callback

  @cursor$ = permit 'browse content by tag',
    success:(client, selector, options, callback)->
      selector.group = makeGroupSelector client.context.group
      @cursor selector, options, callback

  @each$ = permit 'browse content by tag',
    success:(client, selector, fields, options, callback)->
      selector.group = makeGroupSelector client.context.group
      @each selector, fields, options, callback

  @byRelevance = permit 'browse content by tag',
    success: (client, seed, options, callback)->
      [callback, options] = [options, callback] unless callback
      {limit, blacklist, skip}  = options
      limit     ?= 10
      blacklist or= []
      blacklist = blacklist.map(ObjectId)
      cleanSeed = seed.replace(/[^\w\s-]/).trim() #TODO: this is wrong for international charsets
      startsWithSeedTest = RegExp '^'+cleanSeed, "i"
      startsWithOptions = {limit, blacklist, skip}
      @findSuggestions client, startsWithSeedTest, startsWithOptions, (err, suggestions)=>
        if err
          callback err
        else if limit is suggestions.length
            callback null, suggestions
        else
          containsSeedTest = RegExp cleanSeed, 'i'
          containsOptions =
            skip      : skip
            limit     : limit-suggestions.length
            blacklist : blacklist.concat(suggestions.map (o)-> o.getId())
          @findSuggestions client, containsSeedTest, containsOptions, (err, moreSuggestions)->
            if err
              callback err
            else
              allSuggestions = suggestions.concat moreSuggestions
              callback null, allSuggestions

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
