import { readFileSync } from "node:fs";

export const readFileImpl = (path) => () => new Uint8Array(readFileSync(path));
