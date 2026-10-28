// Makes the callable functions reachable after a deploy.
//
// Callables authenticate inside the function (Firebase ID token + `admin`
// claim), so Cloud Run must not require IAM to invoke them. `firebase deploy`
// normally grants `allUsers` run.invoker, but that needs project-IAM rights
// the deploy account (Editor) lacks. Instead this flips the service-level
// `invokerIamDisabled` flag, which Editor can set.
//
// Usage (uses the Firebase CLI login):  npm run enable-callables
// Undo:                                 npm run enable-callables -- --disable
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const PROJECT = 'script-automator-bdbef';
const REGION = 'us-central1';
// Never include openAiProxy: opening it would expose the OpenAI key proxy.
const SERVICES = ['setadminrole', 'banuser'];
const disable = process.argv.includes('--disable');

/**
 * Reuses the access token cached by the Firebase CLI. Any CLI command
 * refreshes it, so run one first (the npm script does).
 */
function accessToken() {
  const cfg = JSON.parse(readFileSync(join(homedir(), '.config/configstore/firebase-tools.json'), 'utf8'));
  const { access_token: token, expires_at: expiresAt } = cfg?.tokens ?? {};
  if (!token) throw new Error('Not logged in: run `firebase login` first.');
  if (expiresAt && expiresAt < Date.now() + 60_000) {
    throw new Error('Cached token expired: run `firebase projects:list` to refresh it, then retry.');
  }
  return token;
}

async function waitForOperation(name, headers) {
  for (let i = 0; i < 60; i++) {
    const op = await (await fetch(`https://run.googleapis.com/v2/${name}`, { headers })).json();
    if (op.done) {
      if (op.error) throw new Error(op.error.message);
      return;
    }
    await new Promise((r) => setTimeout(r, 2000));
  }
  throw new Error(`Timed out waiting for ${name}`);
}

const token = accessToken();
const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

for (const service of SERVICES) {
  const url = `https://run.googleapis.com/v2/projects/${PROJECT}/locations/${REGION}/services/${service}`;
  const res = await fetch(`${url}?updateMask=invokerIamDisabled`, {
    method: 'PATCH',
    headers,
    body: JSON.stringify({ invokerIamDisabled: !disable }),
  });
  if (!res.ok) {
    console.error(`✖ ${service}: HTTP ${res.status} ${await res.text()}`);
    process.exitCode = 1;
    continue;
  }
  await waitForOperation((await res.json()).name, headers);
  const svc = await (await fetch(url, { headers })).json();
  console.log(`✔ ${service}: invokerIamDisabled=${svc.invokerIamDisabled === true}`);
}
