import globals from 'globals'
import { assign } from 'lodash'

export default {
  bootstrap(context = {}) {
    if (['dev', 'default', 'sandbox'].includes(context.ENV)) {
      global._remote = context.remote
      global._globals = globals
    }

    return assign({}, context, {
      registerWindowGlobals: true
    })
  }
}
