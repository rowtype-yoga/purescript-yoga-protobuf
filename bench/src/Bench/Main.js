export const now = () => performance.now();

export const allocations = () => 0;

export const backend = "bun";

export const opaque = (value) => () => value;

let sunk = 0;

export const sink = (value) => () => {
  sunk = (sunk + value) | 0;
};
