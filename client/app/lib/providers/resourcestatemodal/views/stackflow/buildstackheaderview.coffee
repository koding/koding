kd = require 'kd'
JView = require 'app/jview'
WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackHeaderView extends JView

  constructor: (options, data) ->

    super options, data

    @progressPane = new WizardProgressPane()


  pistachio: ->

    '''
      <header>
        {h1{#(title)}}
      </header>
      {{> @progressPane}}
    '''
