fs = require 'fs'
path = require 'path'
crypto = require 'crypto'
es = require 'event-stream'
through2 = require 'through2'
rimraf = require 'rimraf'
clone = require 'clone'

webpack = require 'webpack'
gutil = require 'gulp-util'
vinyl = require 'vinyl-fs'

module.exports = (options={}) -> through2.obj (file, enc, callback) ->
  try config = require(file.path) catch err then return callback(err)
  config = clone(config)
  unless config.output?.filename
    config.output =
      root: '.'
      path: (temp_folder = crypto.rng(16).toString('hex'))
      filename: '[name].js'

  webpack config, (err, stats) =>
    return callback(err) if err
    gutil.log stats.toString({})
    return callback(new Error "Webpack had #{stats.compilation.errors.length} errors") if stats.compilation.errors.length and options.errors

    vinyl.src((path.resolve(path.join(config.output.path, key)) for key of stats.compilation.assets))
      .pipe es.writeArray (err, files) =>
        (gutil.log(err); return @push()) if err

        @push(file) for file in files
        @push()
        rimraf temp_folder, callback
