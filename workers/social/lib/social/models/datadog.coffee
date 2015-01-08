{Base, secure, signature} = require 'bongo'
KodingError = require '../error'

{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class DataDog extends Base

  dogapi = require 'dogapi'

  @share()

  @set
    sharedMethods      :
      static           :
        sendEvent      : (signature Object, Function)
        sendMetrics    : (signature Object, Function)


  {api_key, app_key}   = KONFIG.datadog
  DogApi               = new dogapi {
    api_key, app_key
  }


  Events               =
    MachineStateFailed :
      title            : "vms.failed"
      text             : "VM start failed for user: %nickname%"
      notify           : "@slack-alerts"
      tags             : ["user:%nickname%", "context:vms"]


  tagReplace = (sourceTag, nickname)->

    tags = []

    for tag in sourceTag
      tags.push tag.replace '%nickname%', nickname

    return tags


  @sendEvent = secure (client, data, callback = ->)->

    {connection:{delegate}} = client

    unless delegate.type is 'registered'
      return callback new KodingError "Not allowed"

    {eventName, logs} = data

    ev = Events[eventName]

    unless ev
      return callback new KodingError "Unknown event name"

    {nickname} = delegate.profile

    title = ev.title
    text  = ev.text.replace '%nickname%', nickname
    tags  = tagReplace ev.tags, nickname

    if logs?
      if logs.length < 400
        text += " LOGS: #{logs}"
      else
        text += "\n ------- \n LOGS: #{logs} \n ------- \n"

    if ev.notify?
      text += "\n #{ev.notify}"

    DogApi.add_event {title, text, tags}, (err, res, status)->

      if err?
        console.error "[DataDog] Failed to create event:", err
        err = new KodingError "Failed"

      callback err


  @sendMetrics = secure (client, _metrics, callback = ->)->

    { connection: { delegate } } = client

    unless delegate.type is 'registered'
      return callback new KodingError "Not allowed"

    if not _metrics or _metrics.length is 0
      return callback new KodingError "Metrics required."

    {nickname} = delegate.profile
    metrics    = []
    userTag    = "user:#{nickname}"
    now        = Date.now()/1000

    for metric in _metrics

      # From client side we are sending array of following:
      #
      # eg. "kloud.info:failed:3" -> kloud.info method failed 3 times
      #

      [metric, state, points] = metric.split ':'

      unless metric or state or points?
        return callback new KodingError "Corrupted metrics"

      metric = "client.#{metric}"
      tags   = [userTag, "state:#{state}"]
      points = [[now, points]]

      metrics.push { metric, tags, points }

    DogApi.add_metrics series: metrics, (err)->

      if err?
        console.error "[DataDog] Failed to create event:", err
        err = new KodingError "Failed"

      callback err
