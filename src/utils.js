/**
 * @file utils.js
 * @overview utility functions
 */

/**
  * create an error with additional attributes for generating http responses
  * @param  {String} msg                             - error message
  * @param  {String} [title='Internal Server Error'] - error title
  * @param  {Number} [statusCode=500]                - http status code
  * @return {Error}
  */
export function httpError(msg, title = 'Internal Server Error', statusCode = 500) {
  const err = new Error(msg);
  err.title = title;
  err.statusCode = statusCode;
  return err;
}

/**
  * send http response
  * @param  {Function} done       - callback
  * @param  {String}   body       - response body
  * @param  {Number}   statusCode - resopnse status code
  * @return {Undefined}
  */
export function sendResponse(done, body, statusCode) {
  const payload = { jsonapi: { version: '1.0' } };
  if (body instanceof Error) {
    payload.errors = [{
      title: body.title || 'Internal Server Error',
      detail: body.message,
      status: statusCode.toString(),
    }];
  } else {
    payload.data = {
      type: 'github-webhook-acknowledgement',
      id: body.MessageId,
    };
  }
  done(null, {
    statusCode,
    body: JSON.stringify(payload),
    headers: {
      'Content-Type': 'application/json',
    },
  });
}
