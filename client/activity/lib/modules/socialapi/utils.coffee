_ = require 'lodash'
axios = require 'axios'

###*
 * Default options to requests.
###
axiosDefaultOptions =
  baseURL: '/api/social'
  transformRequest: [ (data) -> JSON.stringify data ]
  headers:
    'Content-Type': 'application/json'
  responseType: 'json'


###*
 * Make an XHR request to social api.
 *
 * @param {String} url - url to hit, it will be merged with `/api/social`
 * @param {Object} options - request options
 * @param {String} options.method - request type (e.g post, get, put, delete)
 * @param {Object} options.data - request params
 * @param {*...} rest - options to pass to axios instance
 * @return {Promise}
###
request = (url, options = {}, rest...) ->

  {method = 'get', data = {}} = options

  options = _.assign {}, axiosDefaultOptions, {url, method, data}

  # this is gonna return a promise instancewith a defined response data
  # structure of axios. We are passing down only response data, not the full
  # data structure. For more info see:
  # https://github.com/mzabriskie/axios#response-api
  return axios(options, rest...).then (response) -> response.data


module.exports = {
  request
}
