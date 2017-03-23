const fs = require('fs');
const path = require('path');
const _ = require('underscore');
const es = require('event-stream');
const through2 = require('through2');
const rimraf = require('rimraf');
const clone = require('clone');
const Async = require('async');

const webpack = require('webpack');
const gutil = require('gulp-util');
const vinyl = require('vinyl-fs');

module.exports = function (options) {
  if (options == null) options = {};
  
  return through2.obj(function (file, enc, callback) {
    let config;
    try { config = require(file.path);
    } catch (error) { return callback(error); }

    config = clone(config);
    if (!config.output || config.output.filename) config.output = { filename: '[name].js' };

    return webpack(config, (err, stats) => {
      if (err) return callback(err);

      gutil.log(stats.toString({}));
      if (stats.compilation.errors.length && options.errors) {
        return callback(new Error(`Webpack had ${stats.compilation.errors.length} errors`));
      }

      const file_paths = ((() => {
        const result = [];
        for (let key in stats.compilation.assets) {
          result.push(path.resolve(path.join(config.output.path, key)));
        }
        return result;
      })());

      return vinyl.src(file_paths)
        .pipe(es.writeArray((err, files) => {
          if (err) gutil.log(err);
          else { for (file of files) this.push(file); }

          return Async.each(file_paths, rimraf, callback);
        }));
    });
  });
};
