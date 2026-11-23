export const newImpl = (input, count) => new Int32Array(count).fill(-1);

export const noteImpl = (fields, wireTypes, tag, position) => {
  const number = tag >>> 3;
  if (number < wireTypes.length && wireTypes[number] === (tag & 7)) fields[number] = position;
  return fields;
};

export const atImpl = (fields, number) => fields[number];
