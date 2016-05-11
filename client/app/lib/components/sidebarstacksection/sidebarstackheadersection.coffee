kd    = require 'kd'
Link  = require 'app/components/common/link'
React = require 'kd-react'


module.exports = class SidebarStackHeaderSection extends React.Component

  onNewClick: (e) ->
    kd.utils.stopDOMEvent e
    kd.singletons.router.handleRoute '/Stack-Editor/New'

  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Home/Stacks'>
        STACKS
        <span className='SidebarSection-secondaryLink' onClick={@bound 'onNewClick'}></span>
      </Link>
      {@props.children}
    </div>
