'use strict';

const { Server } = require('proxy-chain');

function option(name) {
  const prefix = `--${name}=`;
  const value = process.argv.find((arg) => arg.startsWith(prefix));
  return value ? value.slice(prefix.length) : null;
}

const port = Number(option('port'));
const upstream = option('upstream');
if (!Number.isInteger(port) || port < 1 || port > 65535 || !upstream) {
  console.error('Usage: node proxy-server.js --port=PORT --upstream=socks5://host:port');
  process.exit(2);
}
let upstreamUrl;
try { upstreamUrl = new URL(upstream); } catch { process.exit(2); }
if (!['socks:', 'socks5:'].includes(upstreamUrl.protocol)) { process.exit(2); }

const server = new Server({
  host: '127.0.0.1',
  port,
  prepareRequestFunction: () => ({ upstreamProxyUrl: upstream }),
});

async function stop(exitCode) {
  try { await server.close(true); } catch { /* already stopped */ }
  process.exit(exitCode);
}
process.on('SIGINT', () => stop(0));
process.on('SIGTERM', () => stop(0));
server.listen().then(() => console.log(`Listening on 127.0.0.1:${port}`)).catch((error) => { console.error(error.stack || error); process.exit(1); });
