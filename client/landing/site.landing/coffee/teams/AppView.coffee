CustomLinkView    = require './../core/customlinkview'
MainHeaderView    = require './../core/mainheaderview'

module.exports = class TeamsView extends KDView

  constructor: (options = {}, data)->

    super

    {router}  = KD.singletons

    @setPartial '<h1>HELLO TEAMS</h1>'

    @addSubView form = new KDFormView

    form.addSubView new KDInputView
      placeholder : 'your@email.com'

    form.addSubView new KDInputView
      placeholder : 'Company Name'


