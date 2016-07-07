import globals from 'globals'
import { assign } from 'lodash'

export default {
  bootstrap(context = {}) {
    return assign({}, context, { ENV: globals.config.environment })
  }
}
