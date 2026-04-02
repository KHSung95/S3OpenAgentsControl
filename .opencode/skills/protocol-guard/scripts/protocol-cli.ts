import * as fs from "fs";
import * as path from "path";

type Check = {
  name: string;
  pass: boolean;
  detail: string;
};

const SCRIPT_ROOT = path.resolve(__dirname, "..", "..", "..");

function joinRoot(root: string, relPath: string): string {
  return path.join(root, ...relPath.split("/"));
}

function exists(filePath: string): boolean {
  return fs.existsSync(filePath);
}

function readText(filePath: string): string {
  return fs.readFileSync(filePath, "utf8");
}

function findRoot(startDir: string): string {
  let current = startDir;
  while (true) {
    const marker = path.join(current, "opencode.json");
    if (exists(marker)) return current;
    const parent = path.dirname(current);
    if (parent === current) break;
    current = parent;
  }

  const fallbackMarker = path.join(SCRIPT_ROOT, "opencode.json");
  if (exists(fallbackMarker)) return SCRIPT_ROOT;
  return startDir;
}

function extractFrontmatter(content: string): string {
  const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
  return match ? match[1] : "";
}

function getYamlBlock(frontmatter: string, key: string): string {
  const lines = frontmatter.split(/\r?\n/);
  const start = lines.findIndex((line) => line.trim() === `${key}:`);
  if (start === -1) return "";

  const block: string[] = [];
  for (let i = start + 1; i < lines.length; i++) {
    const line = lines[i];
    if (/^[A-Za-z0-9_-]+:\s*/.test(line)) break;
    block.push(line);
  }
  return block.join("\n");
}

function containsAll(content: string, needles: string[]): boolean {
  const lower = content.toLowerCase();
  return needles.every((needle) => lower.includes(needle.toLowerCase()));
}

function printChecks(title: string, checks: Check[]): void {
  console.log(`\n## ${title}`);
  for (const check of checks) {
    const mark = check.pass ? "PASS" : "HOLD";
    console.log(`- [${mark}] ${check.name}: ${check.detail}`);
  }
}

function summarize(checks: Check[]): { pass: boolean; failed: Check[] } {
  const failed = checks.filter((c) => !c.pass);
  return { pass: failed.length === 0, failed };
}

function listWorkerWarnModes(root: string): { name: string; path: string; warn: boolean }[] {
  const workers = [
    { name: "CoderAgent", path: "agents/subagents/code/coder-agent.md" },
    { name: "TestEngineer", path: "agents/subagents/code/test-engineer.md" },
    { name: "CodeReviewer", path: "agents/subagents/code/reviewer.md" },
    { name: "BuildAgent", path: "agents/subagents/code/build-agent.md" },
    { name: "DocWriter", path: "agents/subagents/core/documentation.md" },
    { name: "OpenFrontendSpecialist", path: "agents/subagents/development/frontend-specialist.md" },
    { name: "OpenDevopsSpecialist", path: "agents/subagents/development/devops-specialist.md" },
  ];

  return workers.map((worker) => {
    const filePath = joinRoot(root, worker.path);
    if (!exists(filePath)) {
      return { ...worker, warn: false };
    }
    const content = readText(filePath);
    const warn = /(mode:\s*warn|completion_packet\s+mode="warn")/i.test(content);
    return { ...worker, warn };
  });
}

function runInteractiveHealth(root: string): number {
  const checks: Check[] = [];

  const primaries = [
    { name: "OpenAgent", path: "agents/core/openagent.md" },
    { name: "OpenCoder", path: "agents/core/opencoder.md" },
    { name: "OpenRepoManager", path: "agents/meta/repo-manager.md" },
    { name: "OpenSystemBuilder", path: "agents/meta/system-builder.md" },
  ];

  for (const primary of primaries) {
    const filePath = joinRoot(root, primary.path);
    if (!exists(filePath)) {
      checks.push({
        name: primary.name,
        pass: false,
        detail: `파일 없음 (${primary.path})`,
      });
      continue;
    }

    const content = readText(filePath);
    const frontmatter = extractFrontmatter(content);
    const toolsBlock = getYamlBlock(frontmatter, "tools");
    const permissionBlock = getYamlBlock(frontmatter, "permission");

    const toolsQuestion = /question:\s*true\b/i.test(toolsBlock);
    const permissionQuestion = /question:\s*["']?allow["']?/i.test(permissionBlock);
    const decisionProtocol = containsAll(content, [
      "<interactive_decision_protocol>",
      "question tool",
      "decision_resolution",
    ]);

    const parts: string[] = [];
    parts.push(toolsQuestion ? "tools.question=ok" : "tools.question=missing");
    parts.push(permissionQuestion ? "permission.question=ok" : "permission.question=missing");
    parts.push(decisionProtocol ? "decision-gate=ok" : "decision-gate=missing");

    checks.push({
      name: primary.name,
      pass: toolsQuestion && permissionQuestion && decisionProtocol,
      detail: parts.join(", "),
    });
  }

  const buildCommandPath = joinRoot(root, "commands/build-context-system.md");
  if (!exists(buildCommandPath)) {
    checks.push({
      name: "build-context-system command",
      pass: false,
      detail: "commands/build-context-system.md 파일 없음",
    });
  } else {
    const commandContent = readText(buildCommandPath);
    const hasQuestionCall = /question\s*\(\s*\{/.test(commandContent);
    const ok = hasQuestionCall && containsAll(commandContent, ["decision_resolution", "진행 방식을 선택해 주세요"]);
    checks.push({
      name: "build-context-system command",
      pass: ok,
      detail: ok ? "선택 컴포넌트 강제 규칙 적용됨" : "question/decision_resolution 규칙 누락",
    });
  }

  const subagentFiles = [
    { name: "TaskManager", path: "agents/subagents/core/task-manager.md" },
    { name: "BatchExecutor", path: "agents/subagents/core/batch-executor.md" },
  ];

  for (const sub of subagentFiles) {
    const filePath = joinRoot(root, sub.path);
    if (!exists(filePath)) {
      checks.push({ name: `${sub.name} boundary`, pass: false, detail: `파일 없음 (${sub.path})` });
      continue;
    }

    const content = readText(filePath);
    const frontmatter = extractFrontmatter(content);
    const permissionBlock = getYamlBlock(frontmatter, "permission");
    const denyQuestion = /question:\s*["']?deny["']?/i.test(permissionBlock);
    const decisionRequest = /decision_request/i.test(content);

    checks.push({
      name: `${sub.name} boundary`,
      pass: denyQuestion && decisionRequest,
      detail: `${denyQuestion ? "question deny=ok" : "question deny=missing"}, ${decisionRequest ? "decision_request=ok" : "decision_request=missing"}`,
    });
  }

  printChecks("Interactive Health", checks);
  const summary = summarize(checks);

  console.log("\n## Verdict");
  console.log(summary.pass ? "- PASS: 선택 UI 강제 조건이 충족되었습니다." : "- HOLD: 선택 UI 강제 조건 미충족 항목이 있습니다.");

  if (!summary.pass) {
    console.log("\n## Next Actions");
    for (const failed of summary.failed) {
      console.log(`- ${failed.name}: ${failed.detail}`);
    }
  }

  return summary.pass ? 0 : 2;
}

function runCompactHealth(root: string): number {
  const checks: Check[] = [];

  const protocolPath = joinRoot(root, "context/core/workflows/compact-protocol.md");
  const schemaPath = joinRoot(root, "context/core/workflows/compact-contract-schema.md");
  const compactorPath = joinRoot(root, "agents/subagents/core/contract-compactor.md");
  const taskManagerPath = joinRoot(root, "agents/subagents/core/task-manager.md");
  const batchExecutorPath = joinRoot(root, "agents/subagents/core/batch-executor.md");

  if (exists(protocolPath)) {
    const content = readText(protocolPath);
    checks.push({
      name: "compact-protocol",
      pass: containsAll(content, ["Inheritance check", "dropped_fields", "downgraded_values", "Locale Contract"]),
      detail: "inheritance + locale contract 점검",
    });
  } else {
    checks.push({ name: "compact-protocol", pass: false, detail: "파일 없음" });
  }

  if (exists(schemaPath)) {
    const content = readText(schemaPath);
    checks.push({
      name: "compact-contract-schema",
      pass: containsAll(content, ["output_locale: ko-KR", "Locale Policy", "inheritance_check"]),
      detail: "schema locale/output/inheritance 점검",
    });
  } else {
    checks.push({ name: "compact-contract-schema", pass: false, detail: "파일 없음" });
  }

  if (exists(compactorPath)) {
    const content = readText(compactorPath);
    checks.push({
      name: "ContractCompactor",
      pass: containsAll(content, ["<rule id=\"locale_policy\">", "output_locale: ko-KR", "inheritance_check"]),
      detail: "locale_policy + output_locale + inheritance 점검",
    });
  } else {
    checks.push({ name: "ContractCompactor", pass: false, detail: "파일 없음" });
  }

  if (exists(taskManagerPath)) {
    const content = readText(taskManagerPath);
    checks.push({
      name: "TaskManager contract schema",
      pass: containsAll(content, ["\"output_locale\": \"ko-KR\"", "<conditional_requirements>", "Inheritance check"]),
      detail: "task-level contract replica 필드 점검",
    });
  } else {
    checks.push({ name: "TaskManager contract schema", pass: false, detail: "파일 없음" });
  }

  if (exists(batchExecutorPath)) {
    const content = readText(batchExecutorPath);
    checks.push({
      name: "BatchExecutor carrier mode",
      pass: containsAll(content, ["contract packet carrier", "Inheritance check", "dropped_fields", "downgraded_values"]),
      detail: "carrier boundary + validation gates 점검",
    });
  } else {
    checks.push({ name: "BatchExecutor carrier mode", pass: false, detail: "파일 없음" });
  }

  const warnInventory = listWorkerWarnModes(root);
  const warnWorkers = warnInventory.filter((w) => w.warn).map((w) => w.name);

  checks.push({
    name: "Worker warn inventory",
    pass: true,
    detail: warnWorkers.length > 0 ? `${warnWorkers.length}개 WARN 유지: ${warnWorkers.join(", ")}` : "WARN worker 없음",
  });

  printChecks("Compact Health", checks);
  const summary = summarize(checks);

  console.log("\n## Verdict");
  console.log(summary.pass ? "- PASS: Compact 프로토콜 핵심 항목이 충족되었습니다." : "- HOLD: Compact 프로토콜 누락 항목이 있습니다.");

  if (!summary.pass) {
    console.log("\n## Next Actions");
    for (const failed of summary.failed) {
      console.log(`- ${failed.name}: ${failed.detail}`);
    }
  }

  return summary.pass ? 0 : 2;
}

function runCompactReadiness(root: string, phaseArg: string | undefined): number {
  const phase = (phaseArg || "phase2").toLowerCase();
  if (phase !== "phase2" && phase !== "phase3") {
    console.log(`Unknown phase: ${phaseArg}`);
    console.log("Use: phase2 or phase3");
    return 1;
  }

  const warnInventory = listWorkerWarnModes(root);

  const phaseTargets =
    phase === "phase2"
      ? ["CoderAgent", "TestEngineer", "CodeReviewer"]
      : ["CoderAgent", "TestEngineer", "CodeReviewer", "BuildAgent", "DocWriter", "OpenFrontendSpecialist", "OpenDevopsSpecialist"];

  const targetWarn = warnInventory.filter((worker) => phaseTargets.includes(worker.name) && worker.warn);

  const checks: Check[] = [];
  checks.push({
    name: `${phase.toUpperCase()} warn targets`,
    pass: targetWarn.length === 0,
    detail:
      targetWarn.length === 0
        ? "대상 에이전트가 WARN에서 해제됨"
        : `대상 WARN 잔존: ${targetWarn.map((w) => w.name).join(", ")}`,
  });

  const protocolPath = joinRoot(root, "context/core/workflows/compact-protocol.md");
  const schemaPath = joinRoot(root, "context/core/workflows/compact-contract-schema.md");
  const protocolOk = exists(protocolPath)
    ? containsAll(readText(protocolPath), ["Inheritance check", "Locale Contract"])
    : false;
  const schemaOk = exists(schemaPath)
    ? containsAll(readText(schemaPath), ["output_locale: ko-KR", "inheritance_check"])
    : false;

  checks.push({
    name: "Protocol docs baseline",
    pass: protocolOk && schemaOk,
    detail: protocolOk && schemaOk ? "문서 기준선 충족" : "compact protocol/schema 기준선 미충족",
  });

  printChecks(`Compact Readiness (${phase.toUpperCase()})`, checks);
  const summary = summarize(checks);

  console.log("\n## Verdict");
  console.log(summary.pass ? `- GO: ${phase.toUpperCase()} 전환 가능` : `- HOLD: ${phase.toUpperCase()} 전환 보류`);

  if (!summary.pass) {
    console.log("\n## Blocking Reasons");
    for (const failed of summary.failed) {
      console.log(`- ${failed.name}: ${failed.detail}`);
    }
  }

  return summary.pass ? 0 : 2;
}

function showHelp(): void {
  console.log("Protocol Guard CLI");
  console.log("Usage: protocol-cli.ts <command> [args]");
  console.log("Commands:");
  console.log("  interactive-health");
  console.log("  compact-health");
  console.log("  compact-readiness [phase2|phase3]");
  console.log("  all");
}

function main(): number {
  const root = findRoot(process.cwd());
  const command = (process.argv[2] || "help").toLowerCase();
  const arg = process.argv[3];

  console.log(`# Protocol Guard`);
  console.log(`- root: ${root}`);
  console.log(`- command: ${command}`);

  switch (command) {
    case "interactive-health":
      return runInteractiveHealth(root);
    case "compact-health":
      return runCompactHealth(root);
    case "compact-readiness":
      return runCompactReadiness(root, arg);
    case "all": {
      const a = runInteractiveHealth(root);
      const b = runCompactHealth(root);
      const c = runCompactReadiness(root, arg || "phase2");
      return a === 0 && b === 0 && c === 0 ? 0 : 2;
    }
    default:
      showHelp();
      return command === "help" ? 0 : 1;
  }
}

process.exitCode = main();
