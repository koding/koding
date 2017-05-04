import kd from 'kd'
import lazyrouter from 'app/lazyrouter'

export default function () {
  lazyrouter.bind('analytics', (type, info, state, path, ctx) => {
    kd.singletons.appManager.open('Analytics')
  })
}
