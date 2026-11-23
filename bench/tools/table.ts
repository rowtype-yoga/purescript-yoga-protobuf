// Reads `RESULT <implementation> <message> <operation> <ns/op> <allocs/op>` lines and prints the
// median of each as a Markdown table per runtime: ns/op, and allocs/op on Go.
//
//   bun bench/tools/table.ts < bench/results/raw.txt

const lines = (await Bun.stdin.text()).split("\n").filter((line) => line.startsWith("RESULT "));

const samples = new Map<string, { nanoseconds: number[]; allocations: number[] }>();
for (const line of lines) {
  const [, implementation, message, operation, nanoseconds, allocations] = line.split(/\s+/);
  const key = `${implementation}|${message}|${operation}`;
  const sample = samples.get(key) ?? { nanoseconds: [], allocations: [] };
  sample.nanoseconds.push(Number(nanoseconds));
  sample.allocations.push(Number(allocations));
  samples.set(key, sample);
}

const median = (values: number[]) => {
  const sorted = [...values].sort((left, right) => left - right);
  return sorted[Math.floor(sorted.length / 2)];
};

const columns = ["nested", "repeated-nested", "wide"].flatMap((message) =>
  ["encode", "decode"].map((operation) => ({ message, operation })),
);

const cell = (implementation: string, message: string, operation: string, withAllocations: boolean) => {
  const sample = samples.get(`${implementation}|${message}|${operation}`);
  if (sample === undefined) return "–";
  const nanoseconds = Math.round(median(sample.nanoseconds)).toLocaleString("en");
  return withAllocations ? `${nanoseconds} ns · ${Math.round(median(sample.allocations))}` : `${nanoseconds} ns`;
};

const table = (title: string, implementations: string[], withAllocations: boolean) => {
  const header = `| ${title} | ${columns.map(({ message, operation }) => `${message} ${operation}`).join(" | ")} |`;
  const rule = `|${" --- |".repeat(columns.length + 1)}`;
  const rows = implementations.map(
    (implementation) =>
      `| ${implementation} | ${columns.map(({ message, operation }) => cell(implementation, message, operation, withAllocations)).join(" | ")} |`,
  );
  return [header, rule, ...rows].join("\n");
};

console.log(
  table("Go (ns/op · allocs/op)", ["yoga-protobuf-go", "protoc-gen-go", "vtprotobuf", "hyperpb", "hyperpb-pgo"], true),
);
console.log();
console.log(table("Bun (ns/op)", ["yoga-protobuf-bun", "protobuf-es", "protobufjs"], false));
