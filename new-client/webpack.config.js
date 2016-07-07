var path = require('path');
var webpack = require('webpack');
var FlowStatusWebpackPlugin = require('flow-status-webpack-plugin');
var configData = require('./.config.json')

var BUILD_PATH = path.join(__dirname, '../website/a/p/p', configData.rev)

module.exports = {
  devtool: 'eval',
  entry: [
    'webpack-dev-server/client?http://localhost:1905',
    'webpack/hot/only-dev-server',
    './src/index'
  ],
  resolve: {
    root: path.join(__dirname, 'src'),
    extensions: [ '', '.coffee', '.js', '.json', '.styl' ],
    alias: {
      'legacy/app': path.join(__dirname, '../client/app/lib'),
      'kd': 'kd.js'
    }
  },
  resolveLoader: {
    root: __dirname,
    modulesDirectories: ["node_modules", "web_loaders"],
    alias: {
      'globals-loader': path.join(__dirname, './webpack/web_loaders/globals-loader')
    }
  },
  output: {
    path: BUILD_PATH,
    filename: 'bundle.js',
    publicPath: 'a/p/p/' + configData.rev + '/'
  },
  plugins: [
    new webpack.HotModuleReplacementPlugin(),
    // new FlowStatusWebpackPlugin({
    //   binaryPath: path.join(__dirname, './node_modules/.bin/flow')
    // })
  ],
  module: {
    loaders: [
      { test: require.resolve('./src/globals'), loader: 'globals-loader' },
      { test: /\.js$/, loaders: ['babel'], include: path.join(__dirname, 'src')},
      { test: /\.coffee/, loaders: ['coffee'], include: path.join(__dirname, '../client') }
    ]
  }
};
