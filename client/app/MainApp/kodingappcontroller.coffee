class KodingAppController extends KDViewController

  constructor: (options = {}, data)->

    options.view = new KDView

    super options, data
