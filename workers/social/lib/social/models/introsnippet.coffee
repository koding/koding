jraphical = require 'jraphical'

module.exports = class JIntroSnippet extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    sharedMethods :
      instance    : []
      static      : [ "create", "fetchAll" ]
    schema        :
      introId     :
        type      : String
        required  : yes
      expiry      :
        type      : String
        required  : yes
      name        :
        type      : String
        required  : yes
      snippet     :
        type      : String
        required  : yes

  @create = secure (client, data, callback) ->
    return unless JIntroSnippet.checkPermission client

    introSnippet = new JIntroSnippet data

    introSnippet.save (err)=>
      return callback? err if err
      callback null, introSnippet
      console.log "new intro snippet saved to database"

  @fetchAll = secure (client, callback) ->
    return unless JIntroSnippet.checkPermission client

    JIntroSnippet.some {}, {}, (err, records) ->
      return callback err if err
      callback records

  @checkPermission = (client) ->
    {globalFlags}  = client.connection.delegate
    status = no
    status = yes for flag of globalFlags when globalFlags[flag] is "super-admin"
    console.log "user isn't super admin, go away!" if status is no
    console.log "user is super admin, go on!" if status is yes
    return status