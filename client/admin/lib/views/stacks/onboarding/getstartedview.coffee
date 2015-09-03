kd    = require 'kd'
JView = require 'app/jview'


module.exports = class GetStartedView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'stack-onboarding get-started'

    super options, data

    @getStartedButton = new kd.ButtonView
      cssClass : 'solid medium green'
      title    : 'Get Started!'
      callback : => @emit 'NextPageRequested'


  pistachio: ->

    return """
      <div class="header">
        <p class="title">Stacks</p>
        <p class="description">Stacks let you set up a new developer environment in seconds.</p>
        {{> @getStartedButton}}
      </div>
      <div class="artwork">
        <div class="arrow"></div>
        <div class="item">
          <div class="icon"></div>
          <p>Write a stack file</p>
          <span>Pick the number of servers, and what applications to install.</span>
        </div>
        <div class="item">
          <div class="icon invite-users"></div>
          <p>Invite developers to your team</p>
          <span>Developers get their enviroment set up for them instantly, so they can start working in seconds.</span>
        </div>
      </div>
    """
