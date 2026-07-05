// RTK OpenCode plugin — rewrites bash/shell commands to use rtk for token savings.
// See: https://github.com/rtk-ai/rtk/issues/2516

export default async function RtkOpenCodePlugin() {
  return {
    "tool.execute.before": async (input, output) => {
      const tool = String(input?.tool ?? "").toLowerCase();
      if (tool !== "bash" && tool !== "shell") return;
      const args = output?.args;
      if (!args || typeof args !== "object") return;
      const command = args.command;
      if (typeof command !== "string" || !command) return;

      try {
        const { execSync } = await import("child_process");
        try {
          execSync("/usr/local/bin/rtk rewrite " + JSON.stringify(command), {
            encoding: "utf-8",
            timeout: 3000,
          });
        } catch (e) {
          // rtk rewrite exits with non-zero (3) even on success
          const result = String(e?.stdout || "").trim();
          if (result && result !== command) {
            args.command = result;
          }
        }
      } catch {}
    },
  };
}
