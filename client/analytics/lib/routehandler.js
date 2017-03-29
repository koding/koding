import kd from 'kd'
import lazyrouter from 'app/lazyrouter'

export default function () {
  return lazyrouter.bind('analytics', (type, info, state, path, ctx) => {
    return kd.singletons.appManager.open('Analytics')
  })
}
