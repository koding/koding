class FinderController extends KDController

  KD.registerAppClass this,
    name         : "Finder"
    background   : yes

  constructor:(options, data)->

    options.appInfo = name : "Finder"

    super options, data

  createFileFromPath:(rest...)-> FSHelper.createFileFromPath rest...

  create:(options = {})->

    options.useStorage       ?= yes
    options.addOrphansToRoot ?= no

    new NFinderController options

