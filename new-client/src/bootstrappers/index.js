import registerEnvironment from './registerEnvironment'
import extendGlobals from './extendGlobals'
import initializeBongo from './initializeBongo'
import registerWindowGlobals from './registerWindowGlobals'

const bootstrappers = [
  registerEnvironment,
  extendGlobals,
  initializeBongo,
  registerWindowGlobals
]

export default bootstrappers
