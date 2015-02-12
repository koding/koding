class ProviderWelcomeView extends KDTabPaneView

  constructor:->
    super
      cssClass : "welcome-pane"
      partial  : """
        <h1>Providers for your next Virtual Machine</h1>
        <p>Koding can work with popular service providers,
           and you can build your next server on one of them.</p>
        <p>Select a provider from left to start.</p>
      """
