/**
 * @module log
 * @overview lambda function logger
 */
import { createLogger } from 'bunyan';

import { name, version } from '../package.json';

export const inject = {
  name: 'log',
  require: ['config'],
};

export const logger = createLogger({ name, version });

export default function (config) {
  const options = config.log;
  const log = logger.child(options);
  log.level(options.level);
  return log;
}
