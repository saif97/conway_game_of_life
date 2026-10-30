import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

// Execute a Dart-generated Wasm module on Node 24+ (no browser UI involved).
const path = resolve(process.argv[2]);
const { compile } = await import(pathToFileURL(path.replace(/\.wasm$/, '.mjs')));
const app = await compile(await readFile(path));
const instance = await app.instantiate();
instance.invokeMain();
