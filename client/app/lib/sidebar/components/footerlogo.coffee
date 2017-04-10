React = require 'app/react'


module.exports = SidebarFooterLogo = ({ src })->

  <div className='Sidebar-logo-wrapper'>
    <img className='Sidebar-footer-logo' src={src} />
  </div>
