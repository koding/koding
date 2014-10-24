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

  {api_key, app_key}   = KONFIG.datadog
  DogApi               = new dogapi {
    api_key, app_key
  }

  Events               =
    MachineStateFailed :
      title            : "vms.failed"
      text             : "VM start failed for user: %nickname%"
      notify           : "@slack-_devops"
      tags             : ["user:%nickname%", "context:vms"]


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
    tags  = []

    for tag in ev.tags
      tags.push tag.replace '%nickname%', nickname

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
