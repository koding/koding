kd = require 'kd'

WizardProgressPane = require './wizardprogresspane'

module.exports = class BuildStackHeaderView extends kd.View

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
