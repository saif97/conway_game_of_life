// This module is served from the same base path as the application.
try {
  if (new URL(self.location.href).searchParams.get('wasm') === 'true') {
    const { compileStreaming } = await import('./life_worker.mjs');
    const app = await compileStreaming(fetch(new URL('./life_worker.wasm', import.meta.url)));
    (await app.instantiate()).invokeMain();
  } else {
    // dart2js supports workers; module import executes its self-contained entry.
    await import('./life_worker.js');
  }
} catch (error) {
  self.postMessage({ meta: JSON.stringify({ fatal: `Unable to load simulation worker: ${error}` }) });
}
