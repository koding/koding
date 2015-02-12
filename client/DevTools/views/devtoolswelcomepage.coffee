class DevToolsWelcomePage extends JView

  constructor:(options = {}, data)->

    options.cssClass = KD.utils.curry 'welcome-pane', options.cssClass
    super options, data

    @buttons = new KDView
      cssClass : 'button-container'

    delegate = @getDelegate()
    @addButton title : "Create a New KDApp", delegate.bound 'createNewApp'

  addButton:({title, type}, callback)->

    type ?= ""
    cssClass = "solid big #{type}"

    @buttons.addSubView new KDButtonView {
      title, cssClass, callback
    }

  pistachio:->
    """
      <h1>Koding DevTools</h1>
      <div class="info">
        <p>Koding DevTools is an extensible framework built on top of Koding's own KDFramework that allows you to extend the Koding platform by building apps that other Koding users can install on their VMs. Our users have built installers for software packages like Wordpress, Drupal, Django, etc.</p>

        <p>To learn how to get started with writing your first KD App using DevTools, start at this <a href="http://learn.koding.com/guides/creating-kdapps/">handy guide</a> that will teach you how to use DevTools via the Koding UI or via CLI (command line interface).</p>

        <p>Once you build an app, you can submit it for review. Verified apps show up in the app store instantly! We will also give you credit for the app via our social media channels our blog.</p>

        <p>Happy Koding!</p>
        {{> @buttons}}
      </div>
    """

  click:-> @setClass 'in'
