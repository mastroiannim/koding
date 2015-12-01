errors = require './errors'
koding = require '../../bongo'

sendApiError = (res, err) ->

  response = { error : err }
  return res.status(err.status).send response


sendApiResponse = (res, data) ->

  response = { data }
  return res.status(200).send response


checkApiTokenAvailability = (options, callback) ->

  { JGroup }  = koding.models
  { apiToken } = options

  JGroup.one { slug : apiToken.group }, (err, group) ->

    if err
      return callback errors.internalError

    unless group
      return callback errors.groupNotFound

    unless group.isApiTokenEnabled is true
      return callback errors.apiTokenIsDisabled

    return callback null



isSuggestedUsernameLengthValid = (suggestedUsername) ->

  if 4 <= suggestedUsername?.length <= 15
  then yes
  else no


isUsernameLengthValid = (username) ->

  { JUser } = koding.models
  { minLength, maxLength } = JUser.getValidUsernameLengthRange()

  if minLength <= username?.length <= maxLength
  then yes
  else no



module.exports = {
  sendApiError
  sendApiResponse
  isUsernameLengthValid
  checkApiTokenAvailability
  isSuggestedUsernameLengthValid
}