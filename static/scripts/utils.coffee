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


shallowObjsEqual = (a, b) ->
  for key of a
    return false if a[key] != b[key]
  return true


arraysEqual = (a, b) ->
  """
  One-level deep comparison of the arrays a and b
  Short-circuit-ed for performance

  >>> arraysEqual null, null
  true
  >>> arraysEqual [1, 2], null
  false
  >>> arraysEqual [1, 2], [1, 2]
  true
  >>> arraysEqual [1, 2], [1, 3]
  false
  >>> arraysEqual [1, 2], [1, 2, 3]
  false
  >>> arraysEqual [{a: 1}, {a: 2}], [{a: 1}, {a: 2}]
  true
  >> arraysEqual [{outer: a: 1}, {outer:a: 2}], [{outer: a: 1}, {outer:a: 2}]
  false  # two-level purposefully ignored for performance
  """
  # Type checking purposefully ignored for performance
  #if not (Array.isArray(a) and Array.isArray(b))
  #  console.warn("arguments passed to arraysEqual are not arrays", a, b)
  #  return false
  return true  if !a? and !b?  # null == null
  return false if !a? or  !b?  # null != anything

  return false if a.length != b.length

  for i in [0 ... a.length] by 1
    if typeof a[i] is 'object'
      areEqual = shallowObjsEqual(a[i], b[i])
    else
      areEqual = a[i] == b[i]
    return false if not areEqual

  return true


module.exports = {
  getJSON,
  extend,
  arraysEqual
}