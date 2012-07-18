class JAppScriptAttachment extends jraphical.Attachment
  @setSchema
    as          : String
    description : String
    content     : String
    syntax      : String

class JApp extends jraphical.Module
  
  @mixin Filterable       # brings only static methods
  @mixin Followable       # brings only static methods
  @::mixin Followable::   # brings only prototype methods
  @::mixin Taggable::
  # 
  {Inflector,JsPath,secure,daisy} = bongo
  
  @share()

  @set
    indexes         :
      title         : 'ascending'

    sharedMethods   :
      instance      : [
        "update",'follow', 'unfollow'
        'fetchFollowersWithRelationship', 'fetchFollowingWithRelationship'
      ]
      static        : [
        "one","on","some","create"
        'someWithRelationship','byRelevance'
      ]

    schema          :
      title         : 
        type        : String
        set         : (value)-> value.trim()
        required    : yes
      body          : String
      attachments   : [JAppScriptAttachment]
      counts        :
        followers   :
          type      : Number
          default   : 0
        installed   :
          type      : Number
          default   : 0
      thumbnails    : [Object]
      screenshots   : [Object]
      meta          : require "bongo/bundles/meta"

    relationships   :
      creator       : JAccount
      review        : 
        targetType  : jraphical.Module
        as          : 'review'
      activity      :
        targetType  : CActivity
        as          : 'activity'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      user          :
        targetType  : JAccount
        as          : 'user'
      tag           :
        targetType  : JTag
        as          : 'tag'
  
    # TODO: this should be a race not a daisy
  
  @create = secure (client, data, callback)->
    {connection:{delegate}} = client
    {thumbnails, screenshots, meta:{tags}} = data
    Resource.storeImages client, thumbnails, (err, thumbnailsFilenames)->
      if err
        callback err
      else
        Resource.storeImages client, screenshots, (err, screenshotsFilenames)->
          if err
            callback err
          else
            app = new JApp {
              title       : data.title
              body        : data.body
              thumbnails  : thumbnailsFilenames
              screenshots : screenshotsFilenames
              attachments : [
                {
                  as          : 'script'
                  content     : data.scriptCode
                  description : data.scriptDescription
                  syntax      : data.scriptSyntax
                },{           
                  as          : 'requirements'
                  content     : data.requirementsCode
                  syntax      : data.requirementsSyntax
                }
              ]
            }
            app.save (err)->
              if err
                callback err
              else
                if tags then app.addTags client, tags, (err)->
                  if err
                    callback err
                  else
                    callback null, app

  @findSuggestions = (seed, options, callback)->
    {limit,blacklist}  = options
    
    @some {
      title   : seed
      _id     :
        $nin  : blacklist
    },{
      limit
      sort    : 'title' : 1
    }, callback

