/**
 * @file index.js
 * @overview lambda function entrypoint
 */
import 'source-map-support/register';
import get from 'lodash/get';

import container from './container';
import { sendResponse } from './utils';

export const ERROR = 'event:error';
export const SUCCESS = 'event:success';

/**
 * lambda function handler
 * @param  {Object}   e    - lambda event
 * @param  {Object}   ctx  - function context
 * @param  {Function} done - callback
 * @return {Promise}
 */
export async function handler(e, ctx, done) {
  // freeze the node process immediately on exit
  // see http://docs.aws.amazon.com/lambda/latest/dg/nodejs-prog-model-using-old-runtime.html
  ctx.callbackWaitsForEmptyEventLoop = false;
  const modules = await container.load({
    github: 'github',
    log: 'log',
    sns: 'sns',
  });
  const log = modules.log.child({ req_id: ctx.awsRequestId });
  try {
    log.debug({ event: e }, 'event:received');
    const result = await processEvent(e, { ...modules, log });
    log.debug({ result }, 'event:result');
    log.info(SUCCESS);
    sendResponse(done, result, 200);
  } catch (err) {
    log.error(err, ERROR);
    sendResponse(done, err, err.statusCode || 500);
  }
}

/**
 * process github webhook event
 * @param  {Object} e - lambda event
 * @return {Promise}
 */
export async function processEvent(e, { github, sns }) {
  const signature = github.parseSignature(e);
  const body = get(e, 'body');
  const eventName = get(e, 'headers.X-GitHub-Event');
  github.verifySignature(signature, body);
  return sns.publish({ message: body, subject: eventName });
}
