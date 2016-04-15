React = require 'kd-react'
Link  = require 'app/components/common/link'


module.exports = class SidebarNoStacks extends React.Component


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Home/Welcome'>
        STACKS
      </Link>
      <section className='SidebarSection SidebarStackSection SidebarStackWidgets'>
        <div className='SidebarSection-body'>
          <p>
            Your stacks has not been
            fully configured yet, please
            finalize onboarding steps.
          </p>
          <Link href='/Home/Welcome'>Finalize steps</Link>
        </div>
      </section>
    </div>
