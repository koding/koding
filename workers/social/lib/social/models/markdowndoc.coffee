{Module} = require 'jraphical'

module.exports = class JMarkdownDoc extends Module

  {daisy, secure, ObjectId} = require 'bongo'

  @share()

  @set
    softDelete  : yes
    schema      :
      content   : String
      html      : String
      checksum  : String
      origin    : ObjectId
    sharedMethods   :
      static        : ['generateHTML']

  @generateHTML=(content,options={},callback=->)->
    options.gfm         ?= yes
    options.sanitize    ?= yes
    options.highlight   ?= (code, lang)->
        hljs = require('highlight.js')
        try
          hljs.highlight(lang, code).value
        catch e
          try
            hljs.highlightAuto(code).value
          catch _e
            code
    options.breaks      ?= yes
    options.langPrefix  ?= 'lang-'

    marked = require('marked')
    marked.setOptions options
    markdown = marked content
    callback markdown
    return markdown

  @generateChecksum=(content)->
    require('crypto')
      .createHash('sha1')
      .update(content)
      .digest 'hex'

  update:(atomically)->
    setOp = atomically.$set ?= {}
    setOp.html = JMarkdownDoc.generateHTML setOp.content
    setOp.checksum = JMarkdownDoc.generateChecksum setOp.content
    Module::update.apply this, arguments

  save:->
    @html     = JMarkdownDoc.generateHTML @content
    @checksum = JMarkdownDoc.generateChecksum @content
    super

  @create$ = secure (client, formData, callback)->
    formData.origin = client.connection.delegate.getId()
    @create formData, callback

  @create = (formData, callback)->
    markdownDoc = new @ formData
    markdownDoc.save (err)->
      if err then callback err
      else callback null, markdownDoc
