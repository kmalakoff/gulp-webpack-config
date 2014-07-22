fs = require 'fs'
path = require 'path'
es = require 'event-stream'

webpack = require 'webpack'
gutil = require 'gulp-util'
vinyl = require 'vinyl-fs'

debounceCallback = (callback) ->
  debounced_callback = -> return if debounced_callback.was_called; debounced_callback.was_called = true; callback.apply(null, Array.prototype.slice.call(arguments, 0))
  return debounced_callback

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

    # always delete the generated file (only once)
    file_path = path.resolve(path.join(config.output.path, config.output.filename))
    done = debounceCallback (err, file) ->
      return callback(err, file) if options.hasOwnProperty('pure') and not option.pure
      fs.unlink file_path, -> callback(err, file)

    # create a file
    vinyl.src(file_path, options)
      .pipe(es.map (file, callback) -> done(null, file); callback())
      .on('error', done)
      .on('finish', -> done(new Error "Failed to read #{file_path}"))
