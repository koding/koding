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
        <p class="title">What is a Stack?</p>
        <p class="description">A Stack is a simple definition file that allows
          you to describe default configuration for a virtual machine. This
          configuration is applied automatically to every new VM that is built
          for any new team member. No more "it does not work for me" issues!
          Stacks can easily be modified at a later time.
          <a href="http://learn.koding.com/stacks" target="_blank">Learn more about Stacks.</a>
        </p>
        {{> @getStartedButton}}
      </div>
      <div class="artwork">
        <div class="arrow"></div>
        <div class="item">
          <div class="icon"></div>
          <p>Create a Stack file</p>
          <span>Creating a stack is simple. Pick the number of virtual machines,
          configure their size and decide what default frameworks and servers
          you want installed. Alo "clickety-click"... all easy!</span>
        </div>
        <div class="item">
          <div class="icon invite-users"></div>
          <p>Invite team members</p>
          <span>All invited members get a replica of your defined stack so they
          don't have to futz around with installing and configuring things.
          It's like magic and saves your team so much time!</span>
        </div>
      </div>
    """
