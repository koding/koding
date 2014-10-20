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
        pink           : (signature Object, Function)
        sendEvent      : (signature Object, Function)

  DogApi               = new dogapi
    api_key            : '6d3e00fb829d97cb6ee015f80063627c'
    app_key            : 'c9be251621bc75acf4cd040e3edea17fff17a13a'

  Events               =
    MachineStateFailed :
      title            : "vms.failed"
      text             : "Machine state failed for %nickname%"
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
      text += "\n ------- \n KD.parseLogs() \n #{logs} \n ------- \n"

    if ev.notify?
      text += "\n #{ev.notify}"

    DogApi.add_event {title, text, tags}, (err, res, status)->

      if err?
        console.error "[DataDog] Failed to create event:", err
        err = new KodingError "Failed"

      callback err
