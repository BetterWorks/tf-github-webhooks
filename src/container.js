/**
 * @file container.js
 * @overview function di/ioc container
 */
import Container from 'app-container';

import * as config from './config';
import * as github from './github';
import * as log from './log';
import * as sns from './sns';
import * as ssm from './ssm';

const modules = [
  config,
  github,
  log,
  sns,
  ssm,
];

const container = new Container({
  defaults: { singleton: true },
});

modules.forEach((mod) => container.register(mod, mod.inject));

export default container;
