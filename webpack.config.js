module.exports = {
  context: __dirname + '/static/scripts',
  entry: './entry',
  output: {
    filename: 'static/scripts/bundle.js'
  },

  module: {
    loaders: [
      { test: /\.coffee$/, loader: 'coffee-loader' },
      { test: /\.css$/,    loader: 'style!css' }, // TODO extract text plugin for .css outputting
      { test: /\.sass$/,   loaders: ['style', 'css?sourceMap', 'sass?sourceMap'] }
    ]
  },
  resolve: {
		extensions: ["",
      ".webpack.js", ".webpack.coffee",
      ".web.coffee", ".web.js",
      ".coffee", ".js",

      '.sass', '.css']
	}
};
