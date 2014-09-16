do ->

  handler = (callback) ->
    KD.singleton('appManager').open 'Pricing', callback

  KD.registerRoutes 'Pricing',
    '/:name?/Pricing' : ->
      (KD.getSingleton "router").handleRoute "/Pricing/Developer", replaceState: yes

    '/:name?/Pricing/:section': ({params:{section}}) ->
      handler (app) ->
        app.getView() # .productForm.showSection section

    '/:name?/Pricing/CreateGroup': ->
      KD.remote.api.JGroupPlan.hasGroupCredit (err, hasCredit) ->
        if hasCredit
          handler (app) ->
            app.getView().showGroupForm()
        else
          (KD.getSingleton "router").handleRoute "/Pricing/Team", replaceState: yes
