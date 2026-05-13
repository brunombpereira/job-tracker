declare const __dirname: string;
declare const __filename: string;

declare module "node:path" {
  export function resolve(...paths: string[]): string;
  export function join(...paths: string[]): string;
  export function dirname(p: string): string;
  export function basename(p: string, ext?: string): string;
  export function extname(p: string): string;
  const _default: {
    resolve: typeof resolve;
    join: typeof join;
    dirname: typeof dirname;
    basename: typeof basename;
    extname: typeof extname;
  };
  export default _default;
}

declare module "node:url" {
  export function fileURLToPath(url: string | URL): string;
}
