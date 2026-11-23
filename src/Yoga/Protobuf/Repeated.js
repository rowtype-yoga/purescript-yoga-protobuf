// Every `Repeated` starts as this one array, which is never written to: the first `snoc`
// makes a new array, and the later ones push to it.
export const emptyImpl = Object.freeze([]);

export const snocImpl = (values, value) => {
  if (values === emptyImpl) return [value];
  values.push(value);
  return values;
};

export const freezeImpl = (values) => values;
