// Bundle del Worker de Cacho (Workers + Durable Objects) con esbuild.
// Uso: node do/build.mjs  ->  do/dist/worker.js
import { build } from 'esbuild';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
await build({
  entryPoints: [path.join(here, 'worker.js')],
  bundle: true,
  format: 'esm',
  platform: 'neutral',
  external: ['node:crypto'],
  outfile: path.join(here, 'dist', 'worker.js'),
  logLevel: 'info',
});
