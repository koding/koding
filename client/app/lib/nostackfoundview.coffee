kd = require 'kd'
React = require 'kd-react'
ReactView = require 'app/react/reactview'

module.exports = class NoStackFoundView extends ReactView

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'NoStackFoundView', options.cssClass

    super options, data


  onClick: (event) ->

    { utils, singletons: { router } } = kd

    utils.stopDOMEvent event
    router.handleRoute '/Stack-Editor/New'


  renderReact: ->

    <div className="NoStackFoundView-wrapper">
      <h2>Create your first stack to set up your dev environment</h2>
      <p>
        We will guide you through setting up a stack on Koding. Your stacks
        will be used to build and manage your dev environment. You can read more
        information about stacks <a href="#">here</a>.
      </p>
      <div className='ButtonContainer'>
        <button className='GenericButton' onClick={@bound 'onClick'}>CREATE A STACK</button>
      </div>
    </div>


