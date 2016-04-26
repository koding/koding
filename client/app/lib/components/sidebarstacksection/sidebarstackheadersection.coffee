kd    = require 'kd'
Link  = require 'app/components/common/link'
React = require 'kd-react'


module.exports = class SidebarStackHeaderSection extends React.Component

  onNewStack: (e) ->

    kd.utils.stopDOMEvent e
    @props.onNewStack()


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Home/Stacks'>
        STACKS
        <span className='SidebarSection-secondaryLink' onClick={@bound 'onNewStack'}></span>
      </Link>
      {@props.children}
    </div>
