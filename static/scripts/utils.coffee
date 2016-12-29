xhr = require 'xhr'


getJSON = (url, callback) ->
  xhr {url}, (error, data) ->
    json = JSON.parse data.body
    callback(json, error)


module.exports = getJSON