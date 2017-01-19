htmlencode = require 'htmlencode'
$ = require 'jquery'
kd = require 'kd'
remote = require('../remote')
uuid = require 'uuid'

module.exports = s3upload = (options, callback = kd.noop) ->

  { name, content, mimeType, timeout } = options

  name      ?= uuid.v4()
  mimeType  ?= 'plain/text'
  timeout   ?= 5000

  unless content
    kd.warn 'Content required.'
    return

  name = htmlencode.htmlDecode name

  remote.api.S3.generatePolicy (err, policy) ->

    return callback err  if err?

    data = new FormData()

    data.append 'key', "#{policy.upload_url}/#{name}"
    data.append 'acl', 'public-read'

    # koding-client IAM accessKey provided by S3.generatePolicy
    data.append 'AWSAccessKeyId', policy.accessKey
    data.append 'policy', policy.policy
    data.append 'signature', policy.signature

    # Update this later for feature requirements
    data.append 'Content-Type', mimeType

    data.append 'file', content

    $.ajax
      type        : 'POST'
      url         : policy.req_url
      cache       : no
      contentType : no
      processData : no
      crossDomain : yes
      data        : data
      timeout     : timeout
      error       : (xhr) ->
        responseText = xhr.responseText
        errorCode    = $(responseText).find('Code').text()
        if errorCode is 'EntityTooLarge'
          callback { message: 'The file you tried to upload is too big' }
        else
          callback { message: 'Failed to upload' }
      success     : ->
        callback null, "#{policy.req_url}/#{policy.upload_url}/#{name}"
