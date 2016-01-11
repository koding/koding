{ Base, secure, signature } = require 'bongo'
KodingError = require '../error'

{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class DataDog extends Base

  dogapi = require 'dogapi'

  @share()

  @set
    sharedMethods      :
      static           :
        sendEvent      : (signature Object, Function)
        sendMetrics    : (signature Object, Function)


  { api_key, app_key }   = KONFIG.datadog
  DogApi                 = new dogapi {
    api_key, app_key
  }


  Events =

    MachineStateFailed:
      title  : 'vms.failed'
      text   : 'VM start failed for user: %nickname%'
      notify : '@slack-alerts'
      tags   : ['user:%nickname%', 'version:%version%', 'context:vms']

    TerminalConnectionFailed:
      title  : 'terminal.failed'
      text   : 'Terminal connection failed for user: %nickname%'
      notify : '@slack-alerts'
      tags   : ['user:%nickname%', 'version:%version%', 'context:terminal']

    ForbiddenChannel:
      title  : 'channel.forbidden'
      text   : 'Access is prohibited for channel with token: %channelToken%'
      notify : '@slack-alerts'
      tags   : ['user:%nickname%', 'version:%version%', 'context:pubnub-channel', 'channel-token:%channelToken%']

    MachineTurnedOn:
      title         : 'machine.turnedon'
      text          : 'turned on VM'
      sendToSegment : true
      tags          : []

  tagReplace = (sourceTag, userTags) ->

    parseTag = (tag) ->

      # check if tag contains any variable
      tagMatch = tag.match /%(.*)%$/m

      return tag  unless tagMatch?.length

      # check if tag variable value is set in userTags
      tagValue = userTags[tagMatch[1]]
      return ''  unless tagValue

      return tag.replace /%(.*)%$/g, tagValue

    tags = []

    for tag in sourceTag
      t = parseTag tag
      tags.push t  unless t is ''

    return tags


  parseText = (text, tags) ->
    updatedText = text
    for tag, value of tags
      updatedText = updatedText.replace "%#{tag}%", value

    return updatedText


  @sendEvent = secure (client, data, callback = -> ) ->

    { connection:{ delegate } } = client

    unless delegate
      return callback new KodingError 'Account not found'

    unless delegate?.type is 'registered'
      return callback new KodingError 'Not allowed'

    { eventName, logs, tags } = data
    tags ?= {}
    ev = Events[eventName]

    unless ev
      return callback new KodingError 'Unknown event name'

    { nickname } = delegate.profile
    tags['nickname'] = nickname

    title = ev.title
    text  = parseText ev.text, tags
    tags  = tagReplace ev.tags, tags

    if logs?
      if logs.length < 400
        text += " LOGS: #{logs}"
      else
        text += "\n ------- \n LOGS: #{logs} \n ------- \n"

    if ev.notify?
      text += "\n #{ev.notify}"

    if ev.sendToSegment?
      Tracker  = require './tracker'
      Tracker.track nickname, { subject : ev.text }, data.tags

    DogApi.add_event { title, text, tags }, (err, res, status) ->

      if err?
        console.error '[DataDog] Failed to create event:', err
        err = new KodingError 'Failed'

      callback err


  @sendMetrics = secure (client, _metrics, callback = -> ) ->

    { connection: { delegate } } = client

    unless delegate
      return callback new KodingError 'Account not found'

    unless delegate.type is 'registered'
      return callback new KodingError 'Not allowed'

    if not _metrics or _metrics.length is 0
      return callback new KodingError 'Metrics required.'

    { nickname } = delegate.profile
    metrics    = []
    userTag    = "user:#{nickname}"
    now        = Date.now() / 1000

    for metric in _metrics

      # From client side we are sending array of following:
      #
      # eg. "kloud.info:failed:3" -> kloud.info method failed 3 times
      #

      [metric, state, points] = metric.split ':'

      unless metric or state or points?
        return callback new KodingError 'Corrupted metrics'

      metric = "client.#{metric}"
      tags   = [userTag, "state:#{state}"]
      points = [[now, points]]

      metrics.push { metric, tags, points }

    DogApi.add_metrics { series: metrics }, (err) ->

      if err?
        console.error '[DataDog] Failed to create event:', err
        err = new KodingError 'Failed'

      callback err
