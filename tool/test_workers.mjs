import assert from 'node:assert/strict';
import { Worker } from 'node:worker_threads';

// Execute the real browser bootstrap and generated binaries in independent
// threads. The shim supplies browser worker messaging and file-based fetch.
const shim = `
import { parentPort, workerData } from 'node:worker_threads';
import { readFile } from 'node:fs/promises';
globalThis.self = globalThis;
globalThis.location = { href: workerData.url };
globalThis.postMessage = (data, transfer) => parentPort.postMessage(data, transfer);
globalThis.fetch = async url => new Response(await readFile(new URL(url)), {
  headers: { 'Content-Type': 'application/wasm' }
});
parentPort.on('message', data => globalThis.onmessage({ data }));
await import(workerData.url);
`;
for (const wasm of [false, true]) {
  const url = new URL(`../web/workers/life_worker_bootstrap.js?wasm=${wasm}`, import.meta.url);
  const worker = new Worker(new URL(`data:text/javascript,${encodeURIComponent(shim)}`), { workerData: { url: url.href } });
  let id = 0;
  const pending = new Map();
  let readyResolve, readyReject;
  const ready = new Promise((resolve, reject) => { readyResolve = resolve; readyReject = reject; });
  const timeout = setTimeout(() => readyReject(new Error('Worker startup timed out')), 15000);
  worker.on('error', error => { readyReject(error); for (const {reject} of pending.values()) reject(error); });
  worker.on('message', message => {
    const meta = JSON.parse(message.meta);
    if (meta.ready) return readyResolve();
    if (meta.fatal) return readyReject(new Error(meta.fatal));
    const promise = pending.get(meta.id);
    pending.delete(meta.id);
    if (meta.error) promise.reject(new Error(meta.error));
    else promise.resolve({...meta, cells: message.cells});
  });
  const request = (command, extra = {}) => new Promise((resolve, reject) => {
    const requestId = id++;
    pending.set(requestId, {resolve, reject});
    worker.postMessage(JSON.stringify({id: requestId, command, view: [-50,-50,100,100,1], ...extra}));
  });
  try {
    await ready; clearTimeout(timeout);
    const glider = [[1,0],[2,1],[0,2],[1,2],[2,2]];
    const loaded = await request('load', {pattern: glider});
    assert.equal(loaded.population, 5);
    assert.ok(loaded.cells instanceof Float64Array);
    const result = await request('advance', {exponent:20, view:[262140,262140,262150,262150,1]});
    assert.equal(result.generation,1048576);
    const actual = [];
    for (let i=0;i<result.cells.length;i+=3) actual.push([result.cells[i], result.cells[i+1]]);
    assert.deepEqual(actual.sort(), glider.map(([x,y])=>[x+262144,y+262144]).sort());
    assert.equal((await request('restore')).generation,0);
    await assert.rejects(request('unknown'), /Unknown/);
    assert.equal((await request('frame')).population,5);
    let heartbeats = 0;
    const heartbeat = setInterval(() => heartbeats++, 1);
    try { await request('randomize', {exponent:8, seed:42}); }
    finally { clearInterval(heartbeat); }
    assert.ok(heartbeats > 0, 'Main-thread timers must continue during world creation');
    console.log(`${wasm ? 'Wasm' : 'JavaScript'} worker passed: startup, messages, transferred frames, exact jumps, restore, errors, main-thread heartbeat.`);
  } finally {
    clearTimeout(timeout);
    await worker.terminate();
  }
}
