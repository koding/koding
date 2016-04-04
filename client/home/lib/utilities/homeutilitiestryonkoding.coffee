kd              = require 'kd'
JView           = require 'app/jview'
KodingSwitch    = require 'app/commonviews/kodingswitch'
CustomLinkView  = require 'app/customlinkview'
copyToClipboard = require 'app/util/copyToClipboard'

module.exports = class HomeUtilitiesTryOnKoding extends kd.CustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    super options, data


    @switch  = new KodingSwitch
      cssClass: 'small'
      callback: @bound 'handleSwitch'


    @guide  = new CustomLinkView
      cssClass : 'HomeAppView--button'
      title    : 'VIEW GUIDE'
      href     : 'https://www.koding.com/docs/koding-button'

    @tryOnKoding  = new CustomLinkView
      cssClass : 'TryOnKodingButton fr'
      title    : ''
      callback : kd.noop

    team               = kd.singletons.groupsController.getCurrentGroup()
    { allowedDomains } = team

    # set initial state
    if '*' in allowedDomains
      withCallback = no
      @switch.setOn withCallback
      @setClass 'on'


  handleSwitch: (state) ->

    team               = kd.singletons.groupsController.getCurrentGroup()
    { allowedDomains } = team

    if state
      newDomains = _.clone allowedDomains
      newDomains.push '*'
    else
      _.remove newDomains, (domain) -> domain is '*'

    team.modify { allowedDomains: newDomains }, (err) ->
      if err
        withCallback = no
        @switch.setOn !state
        return

      if state
      then @setClass 'on'
      else @unsetClass 'on'


  click: (event) ->

    return  unless event.target.tagName is 'TEXTAREA'

    copyToClipboard @$('textarea')[0]


  pistachio: ->
    team = kd.singletons.groupsController.getCurrentGroup()
    """
    {{> @switch}}
    <p class='primary'>
      <strong>Enable “Try On Koding” Button</strong>
      Allow access to team stack catalogue for visitors
    </p>
    <p class='secondary'>
      <strong>“Try On Koding” Button</strong>
      Visiting users will have access to all team stack scripts
      <code class='HomeAppView--code block'>
        <textarea spellcheck="false" disabled="disabled"><a href="https://#{team.slug}.koding.com/Join"><img alt="Try on Koding" height="42" width="167" src="https://koding.com/a/img/try_on_koding.png" srcset="https://koding.com/a/img/try_on_koding@1x.png 1x, https://koding.com/a/img/try_on_koding@2x.png 2x" /></a></textarea>
      </code>
      {{> @guide}} {{> @tryOnKoding}}
    </p>
    """
