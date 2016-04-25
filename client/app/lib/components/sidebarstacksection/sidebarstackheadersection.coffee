kd    = require 'kd'
Link  = require 'app/components/common/link'
React = require 'kd-react'


module.exports = class SidebarStackHeaderSection extends React.Component


  openStackEditor: (e) ->

    kd.utils.stopDOMEvent e
    kd.singletons.router.handleRoute '/Stack-Editor'


  render: ->

    <div className='SidebarTeamSection'>
      <Link className='SidebarSection-headerTitle' href='/Stacks'>
        STACKS
        <span className='SidebarSection-secondaryLink' onClick={@bound 'openStackEditor'}></span>
      </Link>
      {@props.children}
    </div>
