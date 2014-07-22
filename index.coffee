fs = require 'fs'
path = require 'path'
es = require 'event-stream'

webpack = require 'webpack'
gutil = require 'gulp-util'
vinyl = require 'vinyl-fs'

debounceCallback = (callback) ->
  debounced_callback = -> return if debounced_callback.was_called; debounced_callback.was_called = true; callback.apply(null, Array.prototype.slice.call(arguments, 0))
  return debounced_callback

getFile = (file, callback) ->
  return callback(null, file) if file.pipe
  vinyl.src(file)
    .pipe es.writeArray (err, files) ->
      return callback(err) if err
      return callback(new Error "Expecting one file for #{file}. Found #{files.length}") if files.length is 0 or files.length > 1
      callback(null, files[0])

module.exports = (options={}) -> es.map (file, callback) ->
  try config = require(file.path) catch err then return callback(err)
  unless config.output?.filename
    (config.output or= {}).filename = path.basename(file.path)
    config.output.filename = config.output.filename.replace(path.extname(config.output.filename), '.js')
    config.output.filename = config.output.filename.replace('.webpack.config', '')
    config.output.filename = config.output.filename.replace('.config', '')

  webpack config, (err, stats) ->
    return callback(err) if err
    gutil.log stats.toString({})
    return callback(new Error "Webpack had #{stats.compilation.errors.length} errors") if stats.compilation.errors.length and options.errors

    # always delete the generated file
    file_path = path.resolve(path.join(config.output.path, config.output.filename))
    getFile file_path, (err, file) ->
      return callback(err, file) if options.hasOwnProperty('pure') and not option.pure
      fs.unlink file_path, -> callback(err, file)
