Link  = require 'app/components/common/link'
React = require 'kd-react'


module.exports = class SidebarStackHeaderSection extends React.Component


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Stacks'>
        STACKS
        <span className='SidebarSection-secondaryLink'></span>
      </Link>
      {@props.children}
    </div>
