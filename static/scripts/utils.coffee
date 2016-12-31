xhr = require 'xhr'


getJSON = (url, callback) ->
  xhr {url}, (error, data) ->
    json = JSON.parse data.body
    callback(json, error)


clone = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  newInstance = new obj.constructor()
  for key of obj
    newInstance[key] = clone obj[key]

  newInstance



extend = (obj, properties) ->
  newObj = clone obj

  for key, val of properties
    newObj[key] = val
  newObj


module.exports = {
    getJSON,
    extend
}