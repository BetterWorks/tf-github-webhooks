const webpack = require('webpack');

module.exports = {
  target: 'node',
  entry: {
    publish: ['babel-polyfill', './lib/publish.js'],
  },
  output: {
    filename: '[name].js',
    libraryTarget: 'commonjs2',
    path: `${__dirname}/dist`,
  },
  module: {
    rules: [
      { test: /\.js$/, use: 'babel-loader' },
    ],
  },
  plugins: [
    new webpack.optimize.UglifyJsPlugin({ sourceMap: true, mangle: false, compress: true }),
  ],
  externals: {
    'aws-sdk': 'aws-sdk',
  },
};
