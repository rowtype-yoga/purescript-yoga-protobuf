export const empty = [];

export const snocImpl = (values, value) => {
  if (values.length === 0) return [value];
  values.push(value);
  return values;
};

export const freeze = (values) => values;

export const thaw = (values) => values;
