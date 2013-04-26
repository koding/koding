jraphical = require 'jraphical'

module.exports = class JIntroSnippet extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    sharedMethods :
      instance    : [ "addToGroup" ]
      static      : [ "create", "fetchAll" ]
    schema        :
      expiry      :
        type      : String
        required  : yes
      name        :
        type      : String
        required  : yes
      snippets    :
        type      : Array
        required  : yes
      overlay     :
        type      : Boolean
        required  : yes
        default   : no

  @create = secure (client, data, callback) ->
    return unless JIntroSnippet.checkPermission client

    introSnippet = new JIntroSnippet data

    introSnippet.save (err)=>
      return callback? err if err
      callback null, introSnippet
      console.log "new intro snippet saved to database"

  @fetchAll = secure (client, callback) ->
    JIntroSnippet.some {}, {}, (err, records) ->
      callback? err, records

  addToGroup: secure (client, data, callback) ->
    @checkPermission client
    @snippets.push
      introId: data.introId
      snippet: data.snippet
    @save()

  @checkPermission = (client) ->
    {globalFlags}  = client.connection.delegate
    status         = no
    status         = yes for flag of globalFlags when globalFlags[flag] is "super-admin"
    console.log "user isn't super admin, go away!" if status is no
    console.log "user is super admin, go on!" if status is yes
    return status

  checkPermission: @checkPermission # is it valid?