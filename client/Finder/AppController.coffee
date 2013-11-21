class FinderController extends AppController

  KD.registerAppClass this,
    name         : "Finder"
    route        : "/Finder"
    hiddenHandle : no

  constructor:(options, data)->

    options.view    = new FinderView
    options.appInfo = name : "Finder"

    super options, data

  createFileFromPath:(rest...)-> FSHelper.createFileFromPath rest...
