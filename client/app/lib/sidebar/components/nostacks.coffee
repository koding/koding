React = require 'app/react'

module.exports = SidebarNoStacks = ({ hasTemplate, hasPermission }) ->

  message = switch
    when hasTemplate
      '''
      Open your dashboard and add your stacks to sidebar to continue.
      '''

    when hasPermission
      '''
      Your stacks has not been fully configured yet, please finalize
      onboarding steps.
      '''

    else
      '''
      Your stacks has not been fully configured yet, please wait until your
      admin sets them up for you.
      '''

  <div className='SidebarTeamSection'>
    <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
      <div className='SidebarSection-body'>
        <p>{message}</p>
      </div>
    </section>
  </div>
