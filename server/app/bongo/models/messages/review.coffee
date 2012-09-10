class JReview extends jraphical.Message

  {ObjectId, ObjectRef, secure} = require 'bongo'
  {log} = console
  @::mixin Likeable::

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
        targetType : JAccount
        as         : 'like'

  delete: secure (client, callback)->
    log "Not implemented yet."
