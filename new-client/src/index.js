import globals from 'globals'

import bootstrappers from './bootstrappers'

import { createKernel } from 'simple-kernel'

const kernel = createKernel({
  bootstrappers
})

kernel.boot().then(context => {
  console.log({context, globals})

  const { remote } = context

  remote.once('ready', () => {
    console.log('remote is ready')
    globals.currentGroup = remote.revive(globals.currentGroup)
    globals.userAccount = remote.revive(globals.userAccount)
    globals.config.entryPoint.slug = globals.currentGroup.slug
  })

  remote.connect()
})


