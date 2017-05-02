var filter = {
  urls: [
    'http://*.koding.io:8090/a/p/p/*'
  ],
  types: [ 'main_frame', 'sub_frame', 'stylesheet', 'script', 'image', 'object', 'xmlhttprequest', 'other']
};

chrome.webRequest.onBeforeRequest.addListener(cb, filter, ['blocking']);

function cb (res) {
  var url = res.url.replace(/^https?:\/\/.+.koding.io/, 'http://localhost');
  console.log(res.url + ' -> ' + url);
  return { redirectUrl: url };
}
