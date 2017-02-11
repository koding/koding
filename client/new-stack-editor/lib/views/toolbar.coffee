debug = (require 'debug') 'nse:toolbar'

kd = require 'kd'
JView = require 'app/jview'

Events = require '../events'


module.exports = class Toolbar extends JView


  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'toolbar', options.cssClass
    data ?= { title: '', accessLevel: 'private', _initial: yes }

    super options, data

    @actionButton = new kd.ButtonView
      cssClass : 'action-button solid green compact'
      title    : 'Initialize'
      icon     : yes
      callback : => @emit Events.InitializeRequested, @getData()._id

    @expandButton = new kd.ButtonView
      cssClass: 'expand'
      callback: ->
        kd.singletons.mainView.toggleSidebar()


  showMissingCredentialWarning: ->

    @unsetClass 'missing-credential'
    kd.utils.defer =>
      @setClass 'missing-credential'


  click: (event) ->

    if event.target.classList.contains 'credential'
      @emit Events.ShowCredentials
      kd.utils.stopDOMEvent event


  setData: (data) ->

    { _id, accessLevel, credentials, title } = data

    if data.accessLevel is 'group'
      accessLevel = 'team'

    if credentials and (providers = Object.keys credentials).length
      count = 0
      for provider in providers when provider isnt 'custom'
        count += credentials[provider].length

    credentials = if count
    then "#{count} credential#{if count > 1 then 's' else ''} is set"
    else 'missing credentials'

    if data._initial
      credentials = '-'
      accessLevel = '-'

    super { _id, accessLevel, credentials, title }


  render: ->

    super

    if @getData().accessLevel is 'team'
    then @setClass   'team'
    else @unsetClass 'team'


  pistachio: ->

    '''
    {cite{}} {h3{#(title)}}
    {.tag.level{#(accessLevel)}} {div.tag.credential{#(credentials)}}
    {div.controls{> @expandButton}} {{> @actionButton}}
    '''
