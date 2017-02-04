fs = require 'fs'
path = require 'path'
_ = require 'underscore'
crypto = require 'crypto'
es = require 'event-stream'
through2 = require 'through2'
rimraf = require 'rimraf'
clone = require 'clone'
Async = require 'async'

webpack = require 'webpack'
gutil = require 'gulp-util'
vinyl = require 'vinyl-fs'

module.exports = (options={}) -> through2.obj (file, enc, callback) ->
  try config = require(file.path) catch err then return callback(err)
  config = clone(config)
  unless config.output?.filename
    config.output =
      path: (temp_folder = crypto.rng(16).toString('hex'))
      filename: '[name].js'

  webpack config, (err, stats) =>
    return callback(err) if err
    gutil.log stats.toString({})
    return callback(new Error "Webpack had #{stats.compilation.errors.length} errors") if stats.compilation.errors.length and options.errors

    file_paths = (path.resolve(path.join(config.output.path, key)) for key of stats.compilation.assets)
    vinyl.src(file_paths)
      .pipe es.writeArray (err, files) =>
        if err then gutil.log(err)
        else
          @push(file) for file in files
        if temp_folder then rimraf(temp_folder, callback) else Async.each(file_paths, rimraf, callback)
