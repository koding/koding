Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class Social extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetchGroupActivity :
          (signature Object, Function)
        editMessage   :
          (signature Object, Function)
        addReply      :
          (signature Object, Function)
        deleteMessage :
          (signature Object, Function)
        likeMessage   :
          (signature Object, Function)
        unlikeMessage :
          (signature Object, Function)
        postToChannel :
          (signature Object, Function)

