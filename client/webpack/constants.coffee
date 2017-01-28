path = require 'path'

{ rev: VERSION } = require '../.config.json'
CLIENT_PATH = path.join __dirname, '..'
BUILD_PATH = path.join CLIENT_PATH, '../website/a/p/p', VERSION
WEBSITE_PATH = path.join CLIENT_PATH, '..', 'website'
THIRD_PARTY_PATH = path.join CLIENT_PATH, './thirdparty'
ASSETS_PATH = path.join CLIENT_PATH, './assets'
COMMON_STYLES_PATH = path.join CLIENT_PATH, 'app/styl/**/*.styl'
PUBNUB_PATH = path.join THIRD_PARTY_PATH, 'pubnub.min.js'
IMAGES_PATH = path.join WEBSITE_PATH, 'a', 'images'
COMPONENT_LAB_PATH = path.join CLIENT_PATH, 'component-lab'
MOCKS_PATH = path.join CLIENT_PATH, 'mocks'
PUBLIC_PATH = "/a/p/p/#{VERSION}/"

ENV_DEV = 'development'
ENV_PROD = 'production'
ENV_TEST = 'test'

MANIFEST_FILE = 'bant.json'
APP_MAIN_FOLDER = 'lib'
JS_BUNDLE_FILE = 'bundle.[name].js'
CSS_BUNDLE_FILE = 'bundle.[name].css'

module.exports = {
  VERSION
  CLIENT_PATH
  BUILD_PATH
  WEBSITE_PATH
  THIRD_PARTY_PATH
  ASSETS_PATH
  COMMON_STYLES_PATH
  PUBNUB_PATH
  IMAGES_PATH
  COMPONENT_LAB_PATH
  MOCKS_PATH
  PUBLIC_PATH

  ENV_DEV
  ENV_PROD
  ENV_TEST

  MANIFEST_FILE
  APP_MAIN_FOLDER
  JS_BUNDLE_FILE
  CSS_BUNDLE_FILE
}
