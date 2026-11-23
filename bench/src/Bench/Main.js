import { readFileSync } from "node:fs";

export const now = () => performance.now();

export const allocations = () => 0;

export const backend = "bun";

export const readFixture = (name) => () => new Uint8Array(readFileSync(`bench/fixtures/${name}.bin`));

export const opaque = (value) => () => value;

let sunk = 0;

export const sink = (value) => () => {
  sunk = (sunk + value) | 0;
};
