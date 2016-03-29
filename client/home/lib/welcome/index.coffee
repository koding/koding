kd                 = require 'kd'
collectCredentials = require 'app/util/collectCredentials'
{ BULLETS }        = require './boxes'

module.exports = class HomeWelcome extends kd.CustomScrollView

  constructor:(options = {}, data)->

    options.cssClass = kd.utils.curry 'WelcomeStacksView', options.cssClass

    super options, data


  viewAppended: ->

    super

    @wrapper.addSubView @welcome = new kd.CustomHTMLView
      tagName : 'section'
      partial : '''
        <h2>Welcome to Koding For Teams!</h2>
        <p>Your new dev environment in the cloud.</p>
        <div class="artboard"></div>
        '''

    @welcome.addSubView @instructions = new kd.CustomHTMLView
      tagName  : 'ul'
      cssClass : 'bullets clearfix'

    { groupsController, computeController } = kd.singletons
    { stacks }                              = computeController

    view  = this

    groupsController.ready -> computeController.ready ->

      { providers, variables } = collectCredentials()

      groupsController.getCurrentGroup().fetchMyRoles (err, roles) ->
        return  kd.warn err  if err
        isAdmin = 'admin' in (roles ? [])
        if isAdmin
        then view.putAdminBullets()
        else view.putUserBullets()


  putAdminBullets: ->

    { stacks } = kd.singletons.computeController

    stacksBox = if stacks.length
      switch stacks.first.status
        when 'NotInitialized' then "<li>#{BULLETS.buildStack}</li>"
        else ''
    else "<li>#{BULLETS.adminStackCreation}</li>"

    @instructions.updatePartial """
      #{stacksBox}
      <li>#{BULLETS.inviteTeam}</li>
      <li>#{BULLETS.installKd}</li>
      """


  putUserBullets: ->

    { stacks } = kd.singletons.computeController

    stacksBox = if stacks.length
      switch stacks.first.status.state
        when 'NotInitialized' then "<li>#{BULLETS.buildStack}</li>"
        else "<li class='disabled'>#{BULLETS.pendingStack}</li>"
    else "<li class='disabled'>#{BULLETS.pendingStack}</li>"

    @instructions.updatePartial """
      #{stacksBox}
      <li>#{BULLETS.userStackCreation}</li>
      <li>#{BULLETS.installKd}</li>
      """
