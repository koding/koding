React = require 'kd-react'
Link  = require 'app/components/common/link'


module.exports = class SidebarNoStacks extends React.Component


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Welcome'>
        STACKS
      </Link>
      <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
        <div className='SidebarSection-body'>
          <p>
            Your stacks has not been
            fully configured yet, please
            finalize onboarding steps.
          </p>
          <Link href='/Welcome'>Finalize steps</Link>
        </div>
      </section>
    </div>
