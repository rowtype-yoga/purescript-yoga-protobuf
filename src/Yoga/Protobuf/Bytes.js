export const eqImpl = (left, right) => {
  if (left.length !== right.length) return false;
  for (let index = 0; index < left.length; index++) {
    if (left[index] !== right[index]) return false;
  }
  return true;
};

export const lengthImpl = (bytes) => bytes.length;

export const fromArrayImpl = (numbers) => Uint8Array.from(numbers);

export const toArrayImpl = (bytes) => Array.from(bytes);

export const emptyImpl = new Uint8Array(0);
