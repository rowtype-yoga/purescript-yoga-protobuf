import { readFileSync, writeSync } from "node:fs";

export const readAllImpl = () => new Uint8Array(readFileSync(0));

// A pipe may take fewer bytes than it's given, so write until it has taken them all.
export const writeAllImpl = (bytes) => {
  let written = 0;
  while (written < bytes.length) written += writeSync(1, bytes, written, bytes.length - written);
};
