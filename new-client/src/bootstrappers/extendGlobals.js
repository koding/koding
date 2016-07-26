import os from 'os'
import { assign } from 'lodash'

import globals from 'globals'

export default {
  bootstrap(context = {}) {
    if (globals.currentGroup) {
      assign(globals.config.entryPoint, {
        slug: globals.currentGroup.slug
      })
    }

    if (globals.config.mainUri == null) {
      assign(globals.config, {
        mainUri: global.location.origin,
        apiUri: global.location.origin
      })
    }

    assign(globals, {
      os,
      keymapType: os === 'mac' ? 'mac' : 'win',
    })

    return assign({}, context, {
      extendGlobals: true
    })
  }
}
