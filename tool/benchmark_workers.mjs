#!/usr/bin/env node
// Benchmark the same generated workers and bootstrap used by the web app.
import { createHash } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { mkdir, readFile, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { Worker } from 'node:worker_threads';

const root = fileURLToPath(new URL('../', import.meta.url));
const fixtures = {
  'hexadecimal-counter': 328591,
  'pi-calculator': 1189325,
  'metapixel-galaxy': 7408195,
  'metapixel-p216-gun': 128116349,
  demonoid: 106639,
};
const help = `Usage: node tool/benchmark_workers.mjs [options]
  --target js|wasm|both       Compiled worker target (default: both)
  --pattern NAME[,NAME...]   Bundled macrocell name, path to .mc, glider, random
                            (default: hexadecimal-counter)
  --exponent N              Generations per jump = 2^N (default: 15)
  --jumps N                 Consecutive jumps per fresh worker (default: 4)
  --samples N               Independent fresh workers per target (default: 1)
  --view L,T,R,B,DETAIL      Fixed viewport (default: initial root, 512 tiles/side)
  --random-size N           Random workload side length (default: 64, max: 512)
  --seed N                  Random workload xorshift32 seed (default: 42)
  --density N               Random workload live fraction (default: 0.25)
  --output PATH             JSON artifact (default: build/benchmarks/<time>.json)
  --worker-dir DIR          Prebuilt worker directory (default: web/workers)
  --baseline PATH           Compare matching configuration, fixtures and states
  --max-regression PERCENT   Fail if median simulation time exceeds baseline
  --profile-dir DIR         Save worker CPU profiles (profiling affects timings)
  --memory                  Sample worker V8 memory outside command timing
  --timeout-ms N            Timeout per command/startup (default: 120000)
  --help                    Show this message

Build workers first: bash tool/build_workers.sh
No restore/replay, renderer, server or browser is involved. See docs/performance.md.
`;

function options(argv) {
  const values = new Map();
  const known = new Set(['target', 'pattern', 'exponent', 'jumps', 'samples', 'view',
    'random-size', 'seed', 'density', 'output', 'baseline', 'max-regression',
    'profile-dir', 'timeout-ms', 'worker-dir', 'memory']);
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--help') { process.stdout.write(help); process.exit(0); }
    const key = argv[i].replace(/^--/, '');
    if (!argv[i].startsWith('--') || !known.has(key) || values.has(key)) {
      throw new Error(`Unknown or repeated option: ${argv[i]}`);
    }
    if (key === 'memory') { values.set(key, true); continue; }
    const value = argv[++i];
    if (!value || value.startsWith('--')) throw new Error(`Missing value for --${key}`);
    values.set(key, value);
  }
  const number = (key, fallback, min, max, integer = true) => {
    const value = Number(values.get(key) ?? fallback);
    if (!Number.isFinite(value) || value < min || value > max || (integer && !Number.isInteger(value))) {
      throw new Error(`--${key} must be ${integer ? 'an integer' : 'a number'} in [${min}, ${max}]`);
    }
    return value;
  };
  const target = values.get('target') ?? 'both';
  if (!['js', 'wasm', 'both'].includes(target)) throw new Error('--target must be js, wasm or both');
  const view = values.has('view') ? values.get('view').split(',').map(Number) : null;
  if (view && (view.length !== 5 || view.some(n => !Number.isFinite(n)) ||
      view[2] <= view[0] || view[3] <= view[1] || view[4] < 1)) {
    throw new Error('--view must be left,top,right,bottom,detail with positive area and detail >= 1');
  }
  if (values.has('max-regression') && !values.has('baseline')) {
    throw new Error('--max-regression requires --baseline');
  }
  const timestamp = new Date().toISOString().replaceAll(':', '-');
  const config = {
    targets: target === 'both' ? ['js', 'wasm'] : [target],
    patterns: (values.get('pattern') ?? 'hexadecimal-counter').split(','),
    exponent: number('exponent', 15, 0, 20),
    jumps: number('jumps', 4, 1, 100000),
    samples: number('samples', 1, 1, 1000),
    view,
    randomSize: number('random-size', 64, 1, 512),
    seed: number('seed', 42, 1, 0xffffffff),
    density: number('density', 0.25, 0, 1, false),
    profiled: values.has('profile-dir'),
    sampleMemory: values.has('memory'),
  };
  return {
    config,
    output: path.resolve(values.get('output') ?? path.join(root, 'build/benchmarks', `${timestamp}.json`)),
    baseline: values.has('baseline') ? path.resolve(values.get('baseline')) : null,
    profileDir: values.has('profile-dir') ? path.resolve(values.get('profile-dir')) : null,
    workerDir: path.resolve(values.get('worker-dir') ?? path.join(root, 'web/workers')),
    timeoutMs: number('timeout-ms', 120000, 1, 3600000),
    maxRegression: values.has('max-regression') ? number('max-regression', 0, 0, 100000, false) : null,
  };
}

const sha256 = data => createHash('sha256').update(data).digest('hex');

async function loadFixture(name, config) {
  if (name === 'glider' || name === 'random') {
    const pattern = name === 'glider' ? [[1, 0], [2, 1], [0, 2], [1, 2], [2, 2]] : [];
    if (name === 'random') {
      let state = config.seed >>> 0;
      for (let y = 0; y < config.randomSize; y++) {
        for (let x = 0; x < config.randomSize; x++) {
          state ^= state << 13;
          state ^= state >>> 17;
          state ^= state << 5;
          if ((state >>> 0) / 0x100000000 < config.density) pattern.push([x, y]);
        }
      }
    }
    return { name, sha256: sha256(JSON.stringify(pattern)), initialPopulation: pattern.length,
      command: 'load', payload: { pattern } };
  }
  const filename = Object.hasOwn(fixtures, name)
    ? path.join(root, 'assets/patterns', `${name}.mc`)
    : path.resolve(name);
  if (!filename.endsWith('.mc')) throw new Error(`Unknown fixture: ${name}`);
  const bytes = await readFile(filename);
  return { name, sha256: sha256(bytes), initialPopulation: fixtures[name] ?? null,
    command: 'loadMacrocell', payload: { source: bytes.toString('utf8') } };
}

// node:inspector must run inside the worker: profiling only this driver misses
// the engine. The extra control channel is separate from app protocol messages.
const shim = `
import { parentPort, workerData } from 'node:worker_threads';
import { readFile, writeFile } from 'node:fs/promises';
import { Session } from 'node:inspector';
let session;
const post = (method, params = {}) => new Promise((resolve, reject) =>
  session.post(method, params, (error, result) => error ? reject(error) : resolve(result)));
globalThis.self = globalThis;
globalThis.location = { href: workerData.url };
globalThis.postMessage = (data, transfer) => parentPort.postMessage(data, transfer);
globalThis.fetch = async url => new Response(await readFile(new URL(url)), {
  headers: { 'Content-Type': 'application/wasm' }
});
parentPort.on('message', async data => {
  if (typeof data === 'string') return globalThis.onmessage({ data });
  try {
    let result;
    if (data.command === 'profileStart') {
      session = new Session();
      session.connect();
      await post('Profiler.enable');
      await post('Profiler.setSamplingInterval', { interval: 1000 });
      await post('Profiler.start');
    } else if (data.command === 'profileStop') {
      const { profile } = await post('Profiler.stop');
      await writeFile(data.path, JSON.stringify(profile));
      await post('Profiler.disable');
      session.disconnect();
      session = undefined;
    } else if (data.command === 'memory') {
      const { heapUsed, heapTotal, external, arrayBuffers } = process.memoryUsage();
      result = { heapUsedBytes: heapUsed, heapTotalBytes: heapTotal,
        externalBytes: external, arrayBuffersBytes: arrayBuffers };
    } else throw new Error('Unknown benchmark control');
    parentPort.postMessage({ benchmarkControl: data.id, result });
  } catch (error) {
    parentPort.postMessage({ benchmarkControl: data.id, error: String(error) });
  }
});
await import(workerData.url);
`;

class WorkerClient {
  constructor(target, timeoutMs, workerDir) {
    this.timeoutMs = timeoutMs;
    this.pending = new Map();
    this.nextId = 1;
    this.closed = false;
    this.failure = null;
    const url = pathToFileURL(path.join(workerDir, 'life_worker_bootstrap.js'));
    url.searchParams.set('wasm', String(target === 'wasm'));
    this.worker = new Worker(new URL(`data:text/javascript,${encodeURIComponent(shim)}`), {
      workerData: { url: url.href },
    });
    this.ready = this.waitFor(0, 'startup');
    this.worker.on('error', error => this.fail(error));
    this.worker.on('exit', code => {
      if (!this.closed) this.fail(new Error(`Worker exited unexpectedly (${code})`));
    });
    this.worker.on('message', message => {
      try {
        const meta = message.benchmarkControl !== undefined ? message : JSON.parse(message.meta);
        if (meta.fatal) return this.fail(new Error(meta.fatal));
        const id = meta.ready ? 0 : (meta.benchmarkControl ?? meta.id);
        const pending = this.pending.get(id);
        if (!pending) return;
        this.pending.delete(id);
        clearTimeout(pending.timeout);
        if (meta.error) pending.reject(new Error(meta.error));
        else pending.resolve({ ...meta, cells: message.cells,
          roundTripUs: (performance.now() - pending.start) * 1000 });
      } catch (error) { this.fail(error); }
    });
  }

  waitFor(id, label) {
    if (this.failure) return Promise.reject(this.failure);
    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => this.fail(new Error(`${label} timed out after ${this.timeoutMs} ms`)), this.timeoutMs);
      this.pending.set(id, { resolve, reject, timeout, start: performance.now() });
    });
  }

  request(command, extra = {}) {
    const id = this.nextId++;
    const reply = this.waitFor(id, command);
    if (!this.failure) {
      this.worker.postMessage(JSON.stringify({ id, command, view: [0, 0, 1, 1, 1], ...extra }));
    }
    return reply;
  }

  control(command, extra = {}) {
    const id = this.nextId++;
    const reply = this.waitFor(id, command);
    if (!this.failure) this.worker.postMessage({ id, command, ...extra });
    return reply;
  }

  fail(error) {
    this.failure ??= error;
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeout);
      pending.reject(error);
    }
    this.pending.clear();
  }

  async close() {
    this.closed = true;
    this.fail(new Error('Worker closed'));
    await this.worker.terminate();
  }
}

function signature(reply) {
  if (!(reply.cells instanceof Float64Array) || reply.cells.length % 4 !== 0) {
    throw new Error('Worker returned invalid viewport tuples');
  }
  const tuples = [];
  for (let i = 0; i < reply.cells.length; i += 4) {
    tuples.push(Array.from(reply.cells.subarray(i, i + 4)));
  }
  tuples.sort((a, b) => a[0] - b[0] || a[1] - b[1] || a[2] - b[2] || a[3] - b[3]);
  return { generation: reply.generation, population: reply.population,
    tupleCount: tuples.length, viewportSha256: sha256(JSON.stringify(tuples)) };
}

function metrics(reply) {
  return {
    simulationUs: reply.elapsedUs,
    roundTripUs: reply.roundTripUs,
    // Includes viewport traversal, serialization, transfer and scheduling.
    otherUs: reply.roundTripUs - reply.elapsedUs,
    nodes: reply.nodes,
    ...(reply.results === undefined ? {} : { results: reply.results }),
    ...(reply.cacheCollections === undefined ? {} : { cacheCollections: reply.cacheCollections }),
    ...(reply.cacheLimit === undefined ? {} : { cacheLimit: reply.cacheLimit }),
    ...(reply.cacheEntriesBeforeLastCollection === undefined ? {} : {
      cacheEntriesBeforeLastCollection: reply.cacheEntriesBeforeLastCollection,
    }),
  };
}

function distribution(values) {
  const sorted = [...values].sort((a, b) => a - b);
  const mid = Math.floor(sorted.length / 2);
  return {
    count: sorted.length,
    median: sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2,
    p95: sorted[Math.ceil(sorted.length * 0.95) - 1],
    min: sorted[0], max: sorted.at(-1),
  };
}

function summarize(rows, jumps) {
  const maximum = get => rows.reduce((value, row) => Math.max(value, get(row) ?? 0), 0);
  return {
    simulationUs: distribution(rows.map(row => row.simulationUs)),
    roundTripUs: distribution(rows.map(row => row.roundTripUs)),
    otherUs: distribution(rows.map(row => row.otherUs)),
    firstJumpSimulationUs: distribution(rows.filter(row => row.jump === 1).map(row => row.simulationUs)),
    finalQuarterSimulationUs: distribution(rows.filter(row => row.jump > Math.floor(jumps * 0.75)).map(row => row.simulationUs)),
    maxNodes: maximum(row => row.nodes),
    maxResults: rows.some(row => row.results !== undefined) ? maximum(row => row.results) : null,
    maxCacheCollections: rows.some(row => row.cacheCollections !== undefined)
      ? maximum(row => row.cacheCollections) : null,
    maxWorkerHeapUsedBytes: rows.some(row => row.workerMemory)
      ? maximum(row => row.workerMemory?.heapUsedBytes) : null,
  };
}

const equal = (a, b) => JSON.stringify(a) === JSON.stringify(b);
function validateBaseline(baseline, artifact) {
  if (baseline.schemaVersion !== artifact.schemaVersion || !baseline.complete) {
    throw new Error('Baseline must be a complete benchmark artifact with the current schema');
  }
  if (!equal(baseline.config, artifact.config) || !equal(baseline.fixtures, artifact.fixtures)) {
    throw new Error('Baseline configuration or fixture hashes differ; use identical workloads, targets, views, jumps and samples');
  }
}

async function buildIdentity(targets, workerDir) {
  const filenames = ['life_worker_bootstrap.js'];
  if (targets.includes('js')) filenames.push('life_worker.js');
  if (targets.includes('wasm')) filenames.push('life_worker.wasm', 'life_worker.mjs', 'life_worker.support.js');
  const result = {};
  for (const filename of filenames) {
    try { result[filename] = sha256(await readFile(path.join(workerDir, filename))); }
    catch (error) { throw new Error(`Cannot read ${filename}; run bash tool/build_workers.sh first`, { cause: error }); }
  }
  return result;
}

function revision() {
  try {
    return {
      commit: execFileSync('git', ['rev-parse', 'HEAD'], { cwd: root, encoding: 'utf8' }).trim(),
      dirty: execFileSync('git', ['status', '--porcelain'], { cwd: root, encoding: 'utf8' }).trim().length > 0,
    };
  } catch { return null; }
}

async function main() {
  const opts = options(process.argv.slice(2));
  if (opts.output === opts.baseline) throw new Error('--output must differ from --baseline');
  const loadedFixtures = [];
  for (const name of opts.config.patterns) loadedFixtures.push(await loadFixture(name, opts.config));
  if (new Set(opts.config.patterns).size !== opts.config.patterns.length) throw new Error('Repeated pattern');
  const artifact = {
    schemaVersion: 1,
    createdAt: new Date().toISOString(),
    complete: false,
    config: opts.config,
    environment: { node: process.version, v8: process.versions.v8, platform: process.platform,
      arch: process.arch, cpu: os.cpus()[0]?.model, cpuCount: os.cpus().length },
    revision: revision(),
    workerDirectory: opts.workerDir,
    workerHashes: await buildIdentity(opts.config.targets, opts.workerDir),
    fixtures: loadedFixtures.map(({ name, sha256, initialPopulation }) => ({ name, sha256, initialPopulation })),
    samples: [], rows: [], summaries: [], comparison: [],
  };
  const baseline = opts.baseline ? JSON.parse(await readFile(opts.baseline, 'utf8')) : null;
  if (baseline) validateBaseline(baseline, artifact);
  if (opts.profileDir) await mkdir(opts.profileDir, { recursive: true });
  await mkdir(path.dirname(opts.output), { recursive: true });
  const expected = new Map();
  try {
    for (const fixture of loadedFixtures) {
      for (const target of opts.config.targets) {
        for (let sample = 1; sample <= opts.config.samples; sample++) {
          const label = `${fixture.name}/${target}/sample ${sample}`;
          const client = new WorkerClient(target, opts.timeoutMs, opts.workerDir);
          let profileFile;
          let profileStarted = false;
          try {
            const ready = await client.ready;
            const loaded = await client.request(fixture.command, fixture.payload);
            if (fixture.initialPopulation !== null && loaded.population !== fixture.initialPopulation) {
              throw new Error(`${label}: initial population mismatch`);
            }
            const [x, y, size] = loaded.bounds;
            const view = opts.config.view ?? [x, y, x + size, y + size, Math.max(1, Math.ceil(size / 512))];
            const frame = await client.request('frame', { view });
            const check = (jump, reply) => {
              const state = signature(reply);
              const key = `${fixture.name}/${jump}`;
              if (expected.has(key) && !equal(expected.get(key), state)) {
                throw new Error(`${label}/jump ${jump}: state differs across targets or fresh samples`);
              }
              expected.set(key, state);
              if (baseline) {
                const previous = jump === 0
                  ? baseline.samples.find(row => row.pattern === fixture.name && row.target === target && row.sample === sample)
                  : baseline.rows.find(row => row.pattern === fixture.name && row.target === target && row.sample === sample && row.jump === jump);
                if (!previous || !equal(previous.signature, state) || !equal(previous.view, view)) {
                  throw new Error(`${label}/jump ${jump}: baseline state or resolved viewport mismatch`);
                }
              }
              return state;
            };
            artifact.samples.push({ pattern: fixture.name, target, sample, view,
              startupUs: ready.roundTripUs, load: metrics(loaded), signature: check(0, frame),
              ...(opts.config.sampleMemory ? { workerMemory: (await client.control('memory')).result } : {}) });
            if (opts.profileDir) {
              profileFile = path.join(opts.profileDir, `${loadedFixtures.indexOf(fixture) + 1}-${path.basename(fixture.name).replace(/[^a-zA-Z0-9_.-]/g, '_')}-${target}-${sample}.cpuprofile`);
              await client.control('profileStart');
              profileStarted = true;
            }
            process.stdout.write(`${label}: ${opts.config.jumps} consecutive jumps of ${2 ** opts.config.exponent} generations\n`);
            for (let jump = 1; jump <= opts.config.jumps; jump++) {
              const reply = await client.request('advance', { exponent: opts.config.exponent, view });
              if (reply.generation !== loaded.generation + jump * 2 ** opts.config.exponent) {
                throw new Error(`${label}/jump ${jump}: generation mismatch`);
              }
              const row = { pattern: fixture.name, target, sample, jump, view,
                signature: check(jump, reply), ...metrics(reply),
                ...(opts.config.sampleMemory ? { workerMemory: (await client.control('memory')).result } : {}) };
              artifact.rows.push(row);
              process.stdout.write(`  ${jump}/${opts.config.jumps}: ${(row.simulationUs / 1000).toFixed(2)} ms simulation, ${(row.roundTripUs / 1000).toFixed(2)} ms round trip, ${reply.population} alive, ${reply.nodes} nodes${row.cacheCollections === undefined ? '' : `, ${row.cacheCollections} collections`}\n`);
            }
          } finally {
            try {
              if (profileStarted && !client.failure) {
                await client.control('profileStop', { path: profileFile });
                artifact.samples.at(-1).profileFile = profileFile;
              }
            } finally { await client.close(); }
          }
          const sampleRows = artifact.rows.filter(row => row.pattern === fixture.name && row.target === target && row.sample === sample);
          artifact.samples.at(-1).summary = summarize(sampleRows, opts.config.jumps);
        }
        const rows = artifact.rows.filter(row => row.pattern === fixture.name && row.target === target);
        const summary = { pattern: fixture.name, target, ...summarize(rows, opts.config.jumps) };
        artifact.summaries.push(summary);
        process.stdout.write(`${fixture.name}/${target}: simulation median ${(summary.simulationUs.median / 1000).toFixed(2)} ms, p95 ${(summary.simulationUs.p95 / 1000).toFixed(2)} ms\n`);
        if (baseline) {
          const previous = baseline.summaries.find(row => row.pattern === fixture.name && row.target === target);
          if (!previous) throw new Error('Baseline summary missing');
          const ratio = previous.simulationUs.median === 0 ? null
            : summary.simulationUs.median / previous.simulationUs.median;
          artifact.comparison.push({ pattern: fixture.name, target,
            baselineMedianUs: previous.simulationUs.median, currentMedianUs: summary.simulationUs.median,
            simulationMedianRatio: ratio, regressionPercent: ratio === null ? null : (ratio - 1) * 100 });
          if (ratio === null) {
            process.stdout.write('  Baseline median is below timer resolution; ratio unavailable; signatures match\n');
            if (opts.maxRegression !== null) throw new Error('Cannot apply regression threshold to a zero-time baseline');
          } else {
            process.stdout.write(`  Baseline median: ${ratio.toFixed(3)}× (${((ratio - 1) * 100).toFixed(1)}% change); signatures match\n`);
          }
        }
      }
    }
    artifact.complete = true;
    if (baseline && !equal(baseline.environment, artifact.environment)) {
      artifact.comparisonWarning = 'Runtime or machine differs from baseline; timings may not be comparable';
      process.stderr.write(`${artifact.comparisonWarning}\n`);
    }
    if (opts.maxRegression !== null && artifact.comparison.some(row => row.regressionPercent > opts.maxRegression)) {
      artifact.thresholdFailure = `Median simulation regression exceeded ${opts.maxRegression}%`;
      process.stderr.write(`${artifact.thresholdFailure}\n`);
      process.exitCode = 1;
    }
  } catch (error) {
    artifact.error = error.stack;
    throw error;
  } finally {
    await writeFile(opts.output, `${JSON.stringify(artifact, null, 2)}\n`);
    process.stdout.write(`Benchmark artifact: ${opts.output}\n`);
  }
}

main().catch(error => { process.stderr.write(`${error.stack}\n`); process.exitCode = 1; });
