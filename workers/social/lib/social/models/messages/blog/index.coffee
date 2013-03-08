JMarkdownDoc = require '../../markdowndoc'
JAccount = require '../../account'
KodingError = require '../../../error'
jraphical = require 'jraphical'

module.exports = class JBlogPost extends jraphical.Message
  # {secure} = require 'bongo'
  # {Relationship} = require 'jraphical'

  {Base,ObjectRef,secure,dash,daisy} = require 'bongo'
  {extend} = require 'underscore'

  @share()

  schema = extend {}, jraphical.Message.schema, {
    content   : String
    html      : String
    checksum  : String
    }

  @generateHTML=(content)->
    require('marked') content

  @generateChecksum=(content)->
    require('crypto')
      .createHash('sha1')
      .update(content)
      .digest 'hex'

  @set
    schema            : schema
    sharedMethods     :
      static          : ['create','one']
      # instance        : [
      #   'reply','restComments','commentsByRange'
      #   'like','fetchLikedByes','mark','unmark','fetchTags'
      #   'delete','modify','fetchRelativeComments','checkIfLikedBefore'
      # ]

  @getAuthorType =-> JAccount

  @create = secure (client, data, callback)->

    constructor = @
    {connection:{delegate}} = client
    unless delegate instanceof constructor.getAuthorType()
      callback new Error 'Access denied!'
    else

      data.html = @generateHTML data.content
      data.checksum = @generateChecksum data.content

      blogpost   = new constructor data

      if delegate.checkFlag 'exempt'
        blogpost.isLowQuality   = yes

      daisy queue = [
        ->
          blogpost
            .sign(delegate)
            .save (err)->
              if err
                callback err
              else queue.next()
        ->
          delegate.addContent blogpost, (err)->
            if err
              callback err
            else queue.next(err)
        ->
          callback blogpost
          queue.next()
      ]
