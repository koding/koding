React    = require 'kd-react'
Scroller = require 'app/components/scroller'

module.exports = class MostReadArticlesWidget extends React.Component

  render: ->

    <div className='MostReadArticlesWidget ActivitySidebar-widget'>
      <h3>Most read articles on Koding University</h3>
      <ol>
        <li>
          <a
            target='_blank'
            href='http://learn.koding.com/guides/ssh-into-your-vm/'>
            How to ssh into your VM?
          </a>
        </li>
        <li>
          <a
            target='_blank'
            href='http://learn.koding.com/guides/getting-started-kpm/'>
            Using the Koding Package Manager
          </a>
        </li>
        <li>
          <a
            target='_blank'
            href='http://learn.koding.com/faq/what-is-koding/'>
            What is Koding?
          </a>
        </li>
        <li>
          <a
            target='_blank'
            href='http://learn.koding.com/guides/getting-started/workspaces/'>
            Getting started with IDE Workspaces
          </a>
        </li>
        <li>
          <a
            target='_blank'
            href='http://learn.koding.com/guides/change-theme/'>
            Changing your IDE and Terminal themes
          </a>
        </li>
      </ol>
      <br />
      <a
        target='_blank'
        href="http://learn.koding.com/">
        More guides on Koding University...
      </a>
    </div>
