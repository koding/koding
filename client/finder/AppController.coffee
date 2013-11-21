class FinderController extends AppController

  KD.registerAppClass this,
    name         : "Finder"
    route        : "/Finder"
    hiddenHandle : no

  constructor:->
    super

  createFileFromPath:(rest...)-> FSHelper.createFileFromPath rest...
