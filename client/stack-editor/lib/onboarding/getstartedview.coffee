kd    = require 'kd'
JView = require 'app/jview'


module.exports = class GetStartedView extends JView

  constructor: (options = {}, data) ->

    options.cssClass = 'StackEditor-OnboardingModal--GetStarted'

    super options, data

    @getStartedButton = new kd.ButtonView
      cssClass : 'GenericButton StackEditor-OnboardingModal--create'
      title    : 'CREATE A NEW STACK'
      callback : => @emit 'NextPageRequested'


  pistachio: ->

    '''
    <header>
      <h1>Create a Stack Template</h1>
    </header>
    <main>
      <h2>Set up a new dev environment</h2>
      <p>
        We will guide you through setting up a stack template.
        Your stack template will be used to build and manage your dev environment.
        You can read more information about stack templates <a href='https://www.koding.com/docs/creating-an-aws-stack'>here</a>.
      </p>
      {{> @getStartedButton}}
    </main>
    '''
