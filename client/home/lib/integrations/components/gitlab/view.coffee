kd               = require 'kd'
React            = require 'kd-react'


module.exports = class GitLabView extends React.Component

  render: ->

    <div className='HomeAppView--sectionWrapper'>
      <strong>GitLab Integration</strong>
      <div>GitLab & Koding together for awesomeness.</div>
      <span className="separator" />
      <GuideButton />
    </div>


# Not sure if these will be necessary, but leaving them here just in case.
# ~Umut
InputArea = ({ value, callback }) ->

   <input type="text"
    className="kdinput text "
    value={value}
    onChange={callback}/>


SaveButton = ({ callback }) ->

  className ="custom-link-view HomeAppView--button primary fr"

  <a className={className} href="#" onClick={callback}>
    <span className="title">SAVE</span>
  </a>


GuideButton = ->

  className = "custom-link-view HomeAppView--button"

  # this might need to change
  href = "https://www.koding.com/docs/gitlab"

  <a className={className} href={href}>
    <span className="title">VIEW GUIDE</span>
  </a>

