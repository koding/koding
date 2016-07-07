import globals from 'globals'
import kookies from 'kookies'
import Bongo from '@koding/bongo-client'
import broker from 'broker-client'
import async from 'async'
import { assign } from 'lodash'

const getSessionToken = () => kookies.get('clientId')

const noop = () => {}

const createInstance = () => {
  let bongoInstance = new Bongo({
    apiEndpoint: globals.config.socialApiUri,
    apiDescriptor: globals.REMOTE_API,
    resourceName: globals.config.resourceName || 'koding-social',
    getSessionToken: getSessionToken,
    getUserArea: () => (globals.config.entryPoint.slug),

    fetchName: ((cache) => (nameStr, callback) => {
      if (cache[nameStr] != null) {
        return callback(null, cache[nameStr], name)
      }
      this.api.JName.one({ name: nameStr }, (err, name) => {
        if (err) {
          return callback(err)
        }
        else if (name == null) {
          return callback(new Error(`Unknown name: ${nameStr}`))
        }
        else if (name.slugs[0].constructorName === 'JUser') {
          name = new this.api.JName({
            name: name.name,
            slugs: [{
              constructorName: 'JAccount',
              collectionName: 'jAccounts',
              slug: name.name,
              usedAsPath: 'profile.nickname'
            }]
          })
        }
        let models = []
        err = null
        queue = name.slugs.map(slug => fin => {
          if (!this.api[slug.constuctorName].one) {
            return
          }
          const selector = { [slug.usedAsPath]: slug.slug }
          this.api[slug.constructor].one(selector, (err, model) => {
            if (err) {
              return callback(err)
            }
            if (!model) {
              err = new Error(`Unable to find model: ${nameStr} of type ${name.constructorName}`)
            }
            models.push(model)
            fin()
          })
        })

        async.parallel(queue, () => {
          this.emit('modalsReady')
          cache[nameStr] = models
          callback(err, models, name)
        })
      })
    })(),

    mq: (() => {
      let authExchange, options;
      authExchange = globals.config.authExchange;
      options = {
        authExchange: authExchange,
        autoReconnect: true,
        getSessionToken: getSessionToken
      };
      console.log('connecting to:' + globals.config.broker.uri);
      return new broker.Broker("" + globals.config.broker.uri, options);
    })()

  });
  return bongoInstance;
};

export default {
  bootstrap(context = {}) {
    return assign({}, context, { remote: createInstance() })
  }
}

