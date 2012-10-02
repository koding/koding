{Message} = require 'jraphical'

class JReview extends Message

  {ObjectId, ObjectRef, secure, dash} = require 'bongo'
  {Relationship}  = require 'jraphical'

  {log} = console

  @trait __dirname, '../../../traits/likeable'

  @share()

  @getDefaultRole =-> 'review'

  @set
    sharedMethods  :
      instance     : ['delete', 'like', 'fetchLikedByes', 'checkIfLikedBefore']
    schema         :
      isLowQuality : Boolean
      body         :
        type       : String
        required   : yes
      originType   :
        type       : String
        required   : yes
      originId     :
        type       : ObjectId
        required   : yes
      deletedAt    : Date
      deletedBy    : ObjectRef
      meta         : require 'bongo/bundles/meta'
    relationships  :
      likedBy      :
        targetType : "JAccount"
        as         : 'like'

  delete: secure (client, callback)->
    {delegate} = client.connection
    {getDeleteHelper} = Relationship
    id = @getId()
    review = @
    queue = [
      ->
        Relationship.one {
          targetId  : id
          as        : 'review'
        }, (err, rel)->
          if err
            queue.fin err
          else
            rel.fetchSource (err, app)->
              if err
                queue.fin err
              else if delegate.can('delete', review) or
                      app.getAt('originId').equals delegate.getId()
                app.removeReview rel, -> queue.fin()
              else
                callback new KodingError 'Access denied!'
      =>
        deleter = ObjectRef(delegate)
        @update
          $unset      :
            body      : 1
          $set        :
            deletedAt : new Date
            deletedBy : deleter
        , -> queue.fin()
    ]
    dash queue, callback
