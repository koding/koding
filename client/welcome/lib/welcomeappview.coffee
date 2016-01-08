kd = require 'kd'

module.exports = class WelcomeAppView extends kd.View

  constructor:->

    super

    @addSubView @welcome = new kd.CustomHTMLView
      tagName : 'section'
      partial : """
        <div class="artboard"></div>
        <h2>Welcome! Let's get started.</h2>
        <p>
          Koding lets your team collaborate and
          work faster, with a development
          environment in the cloud
        </p>
        """


  putAdminInstructions: ->

    @welcome.addSubView new kd.CustomHTMLView
      tagName : 'ul'
      partial : """
        <li>
          <a href='/Admin/Stacks'>
            <cite>1</cite>
            <div>
              <span>Configure user environment</span>
              <span>Setup machine stacks & add their codebase</span>
            </div>
          </a>
        </li>
        <li>
          <a href='/Admin/Invitations'>
            <cite>2</cite>
            <div>
              <span>Invite your team</span>
              <span>Send out invites to your developers</span>
            </div>
          </a>
        </li>
        """


  putProviderInstructions: (providers) ->

    partial = ''
    for p, i in providers
      partial += """
        <li>
          <a href='#'>
            <cite>#{i+1}</cite>
            <div>
              <span>Please authenticate with #{p}!</span>
              <span>we'll be using oauth...</span>
            </div>
          </a>
        </li>
        """

    @welcome.addSubView new kd.CustomHTMLView
      tagName : 'ul'
      partial : partial


  putVariableInstructions: (variables) ->

    i       = 0
    partial = ''
    for own key, val of variables
      partial += """
        <li>
          <a href='#'>
            <cite>#{++i}</cite>
            <div>
              <span>Please type #{key}!</span>
              <span>this will be kept safe & secure</span>
            </div>
          </a>
        </li>
        """

    @welcome.addSubView new kd.CustomHTMLView
      tagName : 'ul'
      partial : partial
