
jraphical = require 'jraphical'
CActivity = require './activity'
KodingError = require '../error'

module.exports = class JTag extends jraphical.Module

  {Relationship} = jraphical

  {ObjectId, ObjectRef, Inflector, daisy, secure, race, signature, dash} = require 'bongo'

  Validators  = require './group/validators'
  {permit}    = require './group/permissionset'

  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/protected'
  @trait __dirname, '../traits/slugifiable'
  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/restrictedquery'
  @trait __dirname, '../traits/notifying'

  @share()

  @set
    softDelete      : yes
    slugifyFrom     : 'title'
    slugTemplate    : ->
      """
      #{if @group is 'koding' then '' else "#{@group}/"}Topics/\#{slug}
      """
    permissions     :
      'read tags'             :
        public                : ['guest', 'member', 'moderator']
        private               : ['member', 'moderator']
      'create tags'           : ['member', 'moderator']
      'freetag content'       : ['member', 'moderator']
      'browse content by tag' : ['member', 'moderator']
      'edit tags'             : ['moderator']
      'delete tags'           : ['moderator']
      'edit own tags'         : ['moderator']
      'delete own tags'       : ['moderator']
      'assign system tag'     : ['moderator']
      'fetch system tag'      : ['moderator']
      'create system tag'     : ['moderator']
      'remove system tag'     : ['moderator']
      # 'delete system tag'     : ['moderator']

    emitFollowingActivities : yes # create buckets for follower / followees
    indexes         :
      # slug          : 'unique'
      title         : 'sparse'
      # group         : 'sparse'
    sharedEvents    :
      static        : ['FollowHappened', 'UnfollowHappened']
      instance      : [
        { name: 'updateInstance' }
      ]
    sharedMethods   :
      instance      :
        modify      :
          (signature Object, Function)
        follow      : [
          (signature Function)
          (signature Object, Function)
        ]
        unfollow:
          (signature Function)
        fetchFollowersWithRelationship:
          (signature Object, Object, Function)
        fetchFollowingWithRelationship:
          (signature Object, Object, Function)
        fetchContents:
          (signature Function)
        fetchContentTeasers: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        addSystemTagToStatusUpdate:
          (signature Object, Function)
        removeTagFromStatus:
          (signature Object, Function)
        fetchSynonym:
          (signature Function)
        delete:
          (signature Function)
        fetchRandomFollowers:
          (signature Object, Function)
        createSynonym:
          (signature String, Function)
      static        :
        one: [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        on:
          (signature String, Function)
        some:
          (signature Object, Object, Function)
        create:
          (signature Object, Function)
        count:
          (signature Object, Function)
        fetchCount:
          (signature Function)
        someWithRelationship:
          (signature Object, Object, Function)
        byRelevance: [
          (signature String, Function)
          (signature String, Object, Function)
        ]
        cursor:
          (signature Object, Object, Function)
        cursorWithRelationship:
          (signature Object, Object, Function)
        fetchMyFollowees:
          (signature [Object], Function)
        each: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        fetchSkillTags:
          (signature Object, Object, Function)
        byRelevanceForSkills: [
          (signature String, Function)
          (signature String, Object, Function)
        ]
        fetchSystemTags:
          (signature Object, Object, Function)
        createSystemTag:
          (signature Object, Object, Function)

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
      meta          : require 'bongo/bundles/meta'
      synonyms      : [String]
      group         : String
      status        : String
      category      :
        type        : String
        default     : "user-tag"
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
      synonym       :
        targetType  : JTag
        as          : "synonymOf"
      content       :
        targetType  : [
          "JNewStatusUpdate"
          # "JCodeSnip"
          # "JNewApp"
          # "JLink"
          # "JTutorial"
          # "JAccount"
          # "JOpinion"
          # "JDiscussion"
          # "JCodeShare"
          # 'JBlogPost'

        ]
        as          : 'post'

  constructor:->
    super
    @notifyGroupWhen 'FollowHappened'

  modify: permit
    advanced: [
      { permission: 'edit own tags', validateWith: Validators.own }
      { permission: 'edit tags' }
    ]
    success: (client, formData, callback)->
      {delegate} = client.connection
      if delegate.checkFlag ['super-admin', 'editor']
        modifiedTag = {slug: formData.slug.trim(), _id: $ne: @getId()}
        JTag.one modifiedTag, (err, tag)=>
          if tag
            callback new KodingError "Slug already exists!"
          else
            @update $set: formData, (err) =>
              return callback err if err
              callback null
      else
        callback new KodingError 'Access denied'

  fetchContentTeasers:(options, selector, callback)->
    [callback, selector] = [selector, callback] unless callback

    selector or= {}
    selector['data.flags.isLowQuality'] = $ne: yes
    selector['status'] = $ne: "deleted"

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
              newTag = {title: tagRef.$suggest.trim(), group}
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

  create = (data, creator, callback) =>
    tag = new JTag data
    tag.createSlug (err, slug)->
      if err then callback err
      else
        tag.slug = slug.slug
        tag.slug_ = slug.slug
        tag.save (err)->
          if err then callback err
          else
            tag.addCreator creator, (err)->
              if err then callback err
              else callback null, tag

  checkTagExistence = (tag, callback) =>
    {title, category} = tag
    @one {title, category}, (err, tag) ->
      return callback err if err
      return callback new KodingError "Tag already exists!" if tag
      callback null

  @create$ = permit 'create tags',
    success: (client, data, callback)->
      {connection:{delegate}} = client
      data.category = "user-tag"
      data.group = client.context.group
      checkTagExistence data, (err) ->
        return callback err if err
        create data, delegate, callback

  createSynonym : permit ['create tags', 'read tags'],
    success: (client, title, callback)->
      addSynonym = (tag) =>
        @addSynonym tag, (err) =>
          return callback err if err
          @update $set: status :'synonym', (err) =>
            return callback err if err
            @constructor.emit 'TagIsSynonym', {tagId:@getId()}
            callback null

      if (@status is 'deleted' or @status is 'synonym')
        return callback new KodingError "Topic is already set as #{@status}!"

      {delegate} = client.connection
      {group} = client.context

      JTag.one {title}, (err, tag) =>
        return callback err if err
        unless tag
          create {title, group}, delegate, (err, tag) =>
            return callback err if err
            addSynonym tag
        else if tag.status is "synonym" or tag.status is "deleted"
          return callback new KodingError "##{tag.title} already set as #{tag.status}!"
        else
          @checkChildSynonyms (err) =>
            return callback err if err
            addSynonym tag

  checkChildSynonyms : (callback) =>
    Relationship.one "targetId": @getId(), "as": "synonymOf", (err, childSynonym) =>
      return callback err if err
      if childSynonym
        return callback new KodingError "##{@title} have child tags! You must first delete them"
      callback null


  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip, category} = options
    {group} = client.context
    @some {
        group
        title   : seed
        _id     :
          $nin  : blacklist
        category: "user-tag"
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

      deleteTag = (err) =>
        tagId = @getId()
        @update {$set: status: "deleted"}, (err)=>
          return callback err if err
          @constructor.emit 'TagIsDeleted', {tagId}
          callback null

      unless delegate.checkFlag('super-admin')
        callback new KodingError 'Access denied'
      else
        if @status is 'deleted'
          return callback new KodingError "Topic is already deleted!"

        if @status is 'synonym'
          return Relationship.remove {sourceId: @getId(), as: "synonymOf"}, deleteTag
        deleteTag null


  @fetchSkillTags:(selector, options, callback)->
    selector.group = 'koding'
    @some selector, options, callback

  @byRelevanceForSkills = permit 'read tags',
    success: (client, seed, options, callback)->
      client.context.group = 'koding'
      @byRelevance client, seed, options, callback

  makeGroupSelector =(group)->
    if Array.isArray group then $in: group else group

  @one$ = permit 'read tags',
    success:(client, uniqueSelector, options, callback)->
      uniqueSelector.group = makeGroupSelector client.context.group
      @one uniqueSelector, options, callback

  @_some = (client, selector, options, callback)->
    selector.group    = makeGroupSelector client.context.group
    selector.category = "user-tag"
    setSelectorStatus client, selector
    @some selector, options, callback

  @some$ = permit 'read tags', success: @_some

  # fix: having read activity permission here may lead to obscurity - SY
  @fetchCount = permit 'read activity',
    success:(client, callback)-> @count callback

  @count$ = permit 'read tags',
    success:(client, selector, callback)->
      [callback, selector] = [selector, callback]  unless callback
      selector ?= {}
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      setSelectorStatus client, selector
      @count selector, callback

  @cursor$ = permit 'read tags',
    success:(client, selector, options, callback)->
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      setSelectorStatus client, selector
      @cursor selector, options, callback

  @each$ = permit 'read tags',
    success:(client, selector, fields, options, callback)->
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      setSelectorStatus client, selector
      @each selector, fields, options, callback

  @byRelevance$ = permit 'read tags',
    success: (client, seed, options, callback)->
      filterSynonyms = (err, tags) ->
        return callback err if err
        resultMap = {}
        deletedTags = []
        synonyms = []
        for tag in tags
          tag.children = []
          switch tag.status
            when 'deleted' then deletedTags.push tag.title
            when 'synonym'
              childTag = tag
              synonyms.push ->
                childTag.fetchSynonym (err, synonym) ->
                  if not err and synonym?
                    resultMap[synonym.getId()] ?= synonym
                    parentTag = resultMap[synonym.getId()]
                    parentTag.children ?= []
                    parentTag.children.push childTag.title
                  synonyms.fin()
            else resultMap[tag.getId()] = tag

        dash synonyms, ->
          result = []
          result.push val for key, val of resultMap
          callback null, result, deletedTags

      @byRelevance client, seed, options, filterSynonyms

  @fetchSystemTags    = permit 'fetch system tag',
   success: (client, selector, options, callback)->
    selector.group    = makeGroupSelector client.context.group
    selector.category = "system-tag"
    @some selector, options, callback

  addSystemTagToStatusUpdate : permit 'assign system tag',
    success: (client, statusUpdate, callback)->
      callback new KodingError "That is not system tag!" unless @category is "system-tag"
      JNewStatusUpdate = require './messages/newstatusupdate'
      JNewStatusUpdate.one _id:statusUpdate._id, (err, status)=>
        callback err if err
        if status
          tagsArray = [
            slug: @slug
          ]
          status.addTags client, tagsArray , (err)->
            callback err, null
        else
          callback new KodingError "Status not found!"

  @createSystemTag = permit 'create system tag',
    success: (client, data, callback)->
      data.category = "system-tag"
      @create client, data, callback

  removeTagFromStatus  = permit 'remove system tag',
    success: (client, statusUpdate, callback)->
      callback new KodingError "That is not system tag!" unless @category is "system-tag"
      JNewStatusUpdate = require './messages/newstatusupdate'
      JNewStatusUpdate.one id:statusUpdate._id, (err, status)=>
        callback err if err
        Relationship.remove {
          targetId    : @getId()
          sourceId    : status.getId()
        } , callback

  fetchRandomFollowers: secure (client, options, callback)->
    {limit}  = options
    limit  or= 3

    Relationship.some {
      as       : "follower"
      sourceId : @getId()
    }, {limit}, (err, rels)->
      accounts = []
      daisy queue = rels.map (r)->
        ->
          JAccount = require './account'
          JAccount.one _id: r.targetId, (err, acc)->
            accounts.push acc  if !err and acc
            queue.next()

      queue.push -> callback null, accounts

  follow: secure (client, options, callback) ->
    [callback, options] = [options, callback] unless callback
    if @status is 'deleted' or @status is 'synonym'
      return callback new KodingError "#{@status} topic cannot be followed"
    Followable = require '../traits/followable'
    Followable::follow.call this, client, options, callback

  setSelectorStatus = (client, selector) ->
    {connection:{delegate}} = client
    selector.status = $nin: ['deleted','synonym'] unless delegate.checkFlag 'super-admin'

