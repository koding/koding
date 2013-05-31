jraphical = require 'jraphical'

module.exports = class JIntroSnippet extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    sharedMethods :
      instance    : [ "addChild", "delete", "deleteChild", "updateChild", "update" ]
      static      : [ "create", "fetchAll" ]
    schema        :
      title       :
        type      : String
        required  : yes
      expiryDate  :
        type      : String
        required  : yes
      visibility  :
        type      : String
        required  : yes
      overlay     :
        type      : String
        required  : yes
      snippets    :
        type      : Array
        required  : yes

  @create = secure (client, data, callback) ->
    return unless JIntroSnippet.checkPermission client

    introSnippet = new JIntroSnippet data
    introSnippet.save (err)=>
      return callback? err if err
      callback null, introSnippet
      console.log "new intro snippet saved to database"

  update: secure (client, data, callback) ->
    return unless data
    @checkPermission client
    @[key] = value for key, value of data
    @save()
    callback?()

  @fetchAll = secure (client, callback) ->
    JIntroSnippet.some {}, {}, (err, records) ->
      callback? err, records

  addChild: secure (client, data, callback) ->
    @checkPermission client
    @snippets.push data
    @save()
    callback?()

  deleteChild: secure (client, introId, callback) ->
    return unless introId
    @checkPermission client
    {snippets} = @
    for snippet in snippets
      if snippet?.introId is introId
        snippets.splice snippets.indexOf(snippet), 1
    @save()
    callback?()

  updateChild: secure (client, data, callback) ->
    return unless data
    @checkPermission client
    {snippets} = @
    for snippet in snippets
      if snippet?.introId is data.oldIntroId
        snippet.introId      = data.introId
        snippet.introTitle   = data.introTitle
        snippet.snippet      = data.snippet
        snippet.placement    = data.placement
        snippet.delayForNext = data.delayForNext
        snippet.callback     = data.callback

    @save()
    callback?()

  @checkPermission = (client) ->
    {globalFlags}  = client.connection.delegate
    status         = no
    status         = yes for flag of globalFlags when globalFlags[flag] is "super-admin"
    return status

  checkPermission: @checkPermission # is it valid?

  delete: secure (client, callback) ->
    @remove callback