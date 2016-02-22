$                   = require 'jquery'
kd                  = require 'kd'
globals             = require 'globals'
whoami              = require 'app/util/whoami'
{ boxes, HANDLERS } = require './boxes'

module.exports = class WelcomeAppView extends kd.View

  constructor:->

    super

    @addSubView @welcome = new kd.CustomHTMLView
      tagName : 'section'
      partial : """
        <h2>Welcome to Koding For Teams!</h2>
        <p>Get your team working faster.</p>
        <div class="artboard"></div>
        """

    @welcome.addSubView @instructions = new kd.CustomHTMLView
      tagName  : 'ul'
      cssClass : 'boxes clearfix'
      click    : @bound 'handleClicks'


  handleClicks: (event) ->

    el = event.target

    return yes  if el.tagName isnt 'A'

    $(el).closest('li').next().removeClass 'dim'

    return yes  if el.getAttribute('href') isnt '#'

    { handler } = el.dataset

    return yes  unless handler

    kd.utils.stopDOMEvent event

    switch handler
      when HANDLERS.skip
        el.classList.add 'dim'

      when HANDLERS.messageAdmin then @messageAdmin()
      when HANDLERS.installKd then @showKdInstallStep el
      # when HANDLERS.buildStack then @buildStack()
      else console.log "#{handler} not yet implemented"


  # buildStack: ->

  #   { computeController } = kd.singletons
  #   { stacks }            = computeController

  #   computeController.verifyStackRequirements stacks.first


  messageAdmin: ->

    ActivityFlux = require 'activity/flux'
    ActivityFlux.actions.thread.switchToDefaultChannelForStackRequest()


  showKdInstallStep: (el) ->

    return @installKd el  if @cmd

    whoami().fetchOtaToken (err, token) =>

      return @cmd = null  if err

      kontrolUrl = if globals.config.environment in ['dev', 'sandbox']
      then "export KONTROLURL=#{globals.config.newkontrol.url}; "
      else ''

      @cmd = "#{kontrolUrl}curl -sL https://kodi.ng/d/kd | bash -s #{token}"

      @installKd el


  installKd: (el) ->

    return new kd.NotificationView 'Please try again later!'  unless @cmd

    el    = document.querySelectorAll('.copy-tooltip.install-kd-command')[0]
    cmdEl = document.querySelectorAll('.copy-tooltip.install-kd-command > div > span')[0]

    cmdEl.innerHTML = @cmd
    el.classList.remove 'hidden'
    kd.utils.selectText cmdEl

    try
      copied = document.execCommand 'copy'
      throw 'couldn\'t copy'  unless copied
    catch
      hintEl = document.querySelectorAll('.copy-tooltip.install-kd-command > i')[0]
      key    = if globals.os is 'mac' then 'Cmd + C' else 'Ctrl + C'

      hintEl.innerHTML = "Hit #{key} to copy!"

    kd.singletons.mainView.mainTabView.scrollToBottom 200


  putAdminInstructions: ->

    { stacks } = kd.singletons.computeController

    stacksBox = if stacks.length
      switch stacks.first.status
        when 'NotInitialized' then "<li>#{boxes.buildStack}</li>"
        else "<li>#{boxes.completeStack}</li>"
    else "<li>#{boxes.configureStack}</li>"

    @instructions.updatePartial """
      #{stacksBox}
      <li class="dim">#{boxes.inviteTeam}</li>
      <li class="dim">#{boxes.installKd}</li>
      """


  putUserInstructions: ->

    { stacks } = kd.singletons.computeController

    stacksBox = if stacks.length
      switch stacks.first.status.state
        when 'NotInitialized' then "<li>#{boxes.buildStack}</li>"
        else "<li>#{boxes.pendingStack}</li>"
    else "<li>#{boxes.pendingStack}</li>"

    @instructions.updatePartial """
      #{stacksBox}
      <li class="dim">#{boxes.installKd}</li>
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
