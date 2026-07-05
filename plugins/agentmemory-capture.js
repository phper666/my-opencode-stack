// ../.config/opencode/plugins/agentmemory-capture.ts
var API = process.env.AGENTMEMORY_URL || "http://localhost:3111";
var FILE_TOOLS = new Set(["Read", "Write", "Edit", "Glob", "Grep"]);
var FILE_KEYS = ["filePath", "file_path", "path", "file", "pattern"];
var MAX_STASHED_FILES = 20;
var DEBUG = process.env.OPENCODE_AGENTMEMORY_DEBUG === "1";
var SECRET = process.env.AGENTMEMORY_SECRET || "";
function authHeaders() {
  const headers = { "Content-Type": "application/json" };
  if (SECRET)
    headers["Authorization"] = `Bearer ${SECRET}`;
  return headers;
}
async function post(path, body, timeoutMs = 5000) {
  try {
    await fetch(`${API}/agentmemory${path}`, {
      method: "POST",
      headers: authHeaders(),
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(timeoutMs)
    });
  } catch (e) {
    if (DEBUG)
      console.error(`[agentmemory] POST ${path} failed:`, e.message);
  }
}
async function postJson(path, body) {
  try {
    const res = await fetch(`${API}/agentmemory${path}`, {
      method: "POST",
      headers: authHeaders(),
      body: JSON.stringify(body),
      signal: AbortSignal.timeout(5000)
    });
    return res.ok ? await res.json() : null;
  } catch (e) {
    if (DEBUG)
      console.error(`[agentmemory] POST ${path} failed:`, e.message);
    return null;
  }
}
async function observe(sessionId, hookType, data) {
  await post("/observe", {
    hookType,
    sessionId,
    project: projectPath,
    cwd: projectPath,
    timestamp: new Date().toISOString(),
    data
  });
}
var activeSessionId = null;
var pendingConfig = null;
var projectPath = null;
var stashedFiles = new Map;
var seenSubtaskIds = new Map;
var seenToolCallIds = new Map;
var contextInjectedSessions = new Set;
var startContextCache = new Map;
function stashFor(sid) {
  let s = stashedFiles.get(sid);
  if (!s) {
    s = new Set;
    stashedFiles.set(sid, s);
  }
  return s;
}
function subtaskSetFor(sid) {
  let s = seenSubtaskIds.get(sid);
  if (!s) {
    s = new Set;
    seenSubtaskIds.set(sid, s);
  }
  return s;
}
function toolCallSetFor(sid) {
  let s = seenToolCallIds.get(sid);
  if (!s) {
    s = new Set;
    seenToolCallIds.set(sid, s);
  }
  return s;
}
function safeSlice(v, max) {
  if (typeof v === "string")
    return v.slice(0, max);
  if (v == null)
    return "";
  try {
    return JSON.stringify(v).slice(0, max);
  } catch {
    return "";
  }
}
var AGENTMEMORY_INSTRUCTIONS = `<agentmemory-instructions>
You have access to agentmemory for persistent cross-session memory. Use these tools proactively.

CORE TOOLS:

memory_save — Save an insight, decision, or fact to long-term memory.
  Required: content (text), concepts (2-5 comma-separated keywords), type (pattern/preference/architecture/bug/workflow/fact)
  Optional: files (comma-separated paths)
  Use when: user says "remember this", after discovering a bug, after making an architectural decision, after learning a project convention.

memory_recall — Search past observations by keywords.
  Use when: user says "recall", "what did we do", "do you remember", or needs context from past sessions.

memory_smart_search — Hybrid semantic+keyword search with progressive disclosure.
  Use when: you need the most relevant past context, fuzzy/conceptual searches, or recall doesn't find what you need.

memory_sessions — List recent sessions with status and observation counts.
  Use when: user asks about session/past history, "what did we work on".

memory_file_history — Get past observations about specific files (across all sessions).
  Use when: you're about to edit a file and want to know its history, common pitfalls, or past edits.

memory_lesson_save — Save a lesson learned (what worked, what to avoid).
  Use when: you discover a pattern that could help future sessions avoid mistakes.

memory_lesson_recall — Search lessons by query. Returns lessons sorted by confidence.
  Use when: before making a decision, check if past lessons apply.

memory_governance_delete — Delete specific memories. Requires explicit user confirmation.
  Use when: user says "forget this", "delete that memory".

memory_patterns — Detect recurring patterns across sessions.
  Use when: you want to understand project-level trends over time.

memory_consolidate — Run the 4-tier memory consolidation pipeline.
  Use when: you want to compress and organize accumulated session observations.

All memory tools start with \`agentmemory_memory_\`. Use the exact names as they appear in your tool list. Tool results are JSON. Always check what was returned before presenting to the user.
</agentmemory-instructions>`;
function extractFilePaths(args) {
  const files = [];
  for (const key of FILE_KEYS) {
    const val = args[key];
    if (typeof val === "string" && val.length > 0) {
      files.push(val);
    }
  }
  return files;
}
function extractErrorMessage(err) {
  if (typeof err === "string")
    return err;
  if (err && typeof err === "object") {
    const e = err;
    if (typeof e.message === "string")
      return e.message;
    if (e.data && typeof e.data === "object") {
      const d = e.data;
      if (typeof d.message === "string")
        return d.message;
    }
    if (typeof e.name === "string")
      return e.name;
    try {
      return JSON.stringify(err);
    } catch {
      return "";
    }
  }
  return String(err ?? "");
}
var AgentmemoryCapturePlugin = async (ctx) => {
  projectPath = ctx.worktree || ctx.project?.id || process.cwd();
  return {
    event: async ({ event }) => {
      const type = event.type;
      const props = event.properties || {};
      if (type === "session.created") {
        const info = props.info;
        activeSessionId = info?.id || props.sessionID || null;
        if (!activeSessionId)
          return;
        stashedFiles.set(activeSessionId, new Set);
        seenSubtaskIds.delete(activeSessionId);
        seenToolCallIds.delete(activeSessionId);
        contextInjectedSessions.delete(activeSessionId);
        const sessionId = activeSessionId;
        const startResult = await postJson("/session/start", {
          sessionId,
          title: info?.title ?? null,
          parentID: info?.parentID ?? null,
          version: info?.version ?? null,
          project: projectPath,
          cwd: projectPath
        });
        const startCtx = startResult?.context;
        if (typeof startCtx === "string" && startCtx.length > 0) {
          startContextCache.set(sessionId, startCtx);
        }
        if (pendingConfig) {
          await observe(sessionId, "config_loaded", pendingConfig);
          pendingConfig = null;
        }
      }
      if (type === "session.status") {
        const status = props.status;
        const sid = props.sessionID || activeSessionId;
        if (!sid || !status)
          return;
        if (status.type === "idle") {
          await post("/summarize", { sessionId: sid });
        }
        await observe(sid, "session_status", {
          status_type: status.type,
          attempt: status.attempt ?? null,
          message: safeSlice(status.message, 2000)
        });
      }
      if (type === "session.compacted") {
        const sid = props.sessionID || activeSessionId;
        if (sid) {
          await post("/summarize", { sessionId: sid });
          await observe(sid, "session_compacted", {});
        }
      }
      if (type === "session.updated") {
        const info = props.info;
        const sid = info?.id || props.sessionID || activeSessionId;
        if (!sid)
          return;
        await observe(sid, "session_updated", {
          title: info?.title ?? null,
          parentID: info?.parentID ?? null,
          additions: info?.summary?.additions ?? null,
          deletions: info?.summary?.deletions ?? null,
          files: info?.summary?.files ?? null
        });
      }
      if (type === "session.diff") {
        const sid = props.sessionID || activeSessionId;
        if (!sid || !Array.isArray(props.diff))
          return;
        const diffs = props.diff;
        await observe(sid, "session_diff", {
          files: diffs.map((d) => d.file),
          additions: diffs.reduce((s, d) => s + (d.additions || 0), 0),
          deletions: diffs.reduce((s, d) => s + (d.deletions || 0), 0),
          diffs: diffs.slice(0, 50)
        });
      }
      if (type === "session.deleted") {
        const sid = props.info?.id || props.sessionID || activeSessionId;
        if (!sid) {
          if (DEBUG)
            console.error("[agentmemory] session.deleted with no session ID");
          return;
        }
        await post("/session/end", { sessionId: sid });
        post("/crystals/auto", { olderThanDays: 7 }, 30000);
        post("/consolidate-pipeline", { tier: "all", force: true }, 30000);
        if (sid === activeSessionId)
          activeSessionId = null;
        stashedFiles.delete(sid);
        startContextCache.delete(sid);
        seenSubtaskIds.delete(sid);
        seenToolCallIds.delete(sid);
        contextInjectedSessions.delete(sid);
      }
      if (type === "session.error") {
        const sid = props.sessionID || activeSessionId;
        if (sid) {
          await observe(sid, "post_tool_failure", {
            tool_name: "session.error",
            tool_input: "",
            tool_output: safeSlice(props.error, 8000)
          });
        }
      }
      if (type === "message.updated") {
        const info = props.info;
        if (!info)
          return;
        if (info.role === "assistant") {
          const sid = props.sessionID || info.sessionID || activeSessionId;
          if (!sid)
            return;
          const tokens = info.tokens;
          const error = info.error ? extractErrorMessage(info.error) : null;
          await observe(sid, "assistant_message", {
            messageID: info.id,
            parentID: info.parentID,
            modelID: info.modelID,
            providerID: info.providerID,
            mode: info.mode,
            cost: info.cost ?? 0,
            tokens: {
              input: tokens?.input ?? 0,
              output: tokens?.output ?? 0,
              reasoning: tokens?.reasoning ?? 0,
              cache_read: tokens?.cache?.read ?? 0,
              cache_write: tokens?.cache?.write ?? 0
            },
            finish: info.finish ?? null,
            error,
            duration_ms: info.time && typeof info.time.completed === "number" ? info.time.completed - (info.time.created || 0) : null
          });
        }
      }
      if (type === "message.removed") {
        const sid = props.sessionID || activeSessionId;
        if (sid) {
          await observe(sid, "message_removed", {
            messageID: props.messageID
          });
        }
      }
      if (type === "message.part.updated") {
        const part = props.part;
        if (!part)
          return;
        const sid = part.sessionID || props.sessionID || activeSessionId;
        if (!sid)
          return;
        if (part.type === "subtask") {
          const subtaskId = part.id;
          if (!subtaskId)
            return;
          const subtaskSet = subtaskSetFor(sid);
          if (subtaskSet.has(subtaskId))
            return;
          subtaskSet.add(subtaskId);
          await observe(sid, "subagent_start", {
            subtask_id: part.id,
            agent: part.agent,
            prompt: safeSlice(part.prompt, 4000),
            description: safeSlice(part.description, 2000)
          });
          return;
        }
        if (part.type === "tool") {
          const state = part.state;
          if (!state)
            return;
          const callId = part.callID;
          if (!callId)
            return;
          const toolName = part.tool;
          if (state.status === "completed") {
            const callSet = toolCallSetFor(sid);
            if (callSet.has(callId))
              return;
            callSet.add(callId);
            const st = state;
            const rawTime = st.time || {};
            const startTime = typeof rawTime.start === "number" ? rawTime.start : null;
            const endTime = typeof rawTime.end === "number" ? rawTime.end : null;
            await observe(sid, "post_tool_use", {
              tool_name: toolName,
              call_id: callId,
              tool_input: safeSlice(st.input, 4000),
              tool_output: safeSlice(st.output, 8000),
              title: st.title ?? null,
              metadata: st.metadata || {},
              duration_ms: startTime != null && endTime != null ? endTime - startTime : null,
              attachments: Array.isArray(st.attachments) ? st.attachments.map((a) => a.filename || a.url) : []
            });
          } else if (state.status === "error") {
            const callSet = toolCallSetFor(sid);
            if (callSet.has(callId))
              return;
            callSet.add(callId);
            const st = state;
            const rawTime = st.time || {};
            const startTime = typeof rawTime.start === "number" ? rawTime.start : null;
            const endTime = typeof rawTime.end === "number" ? rawTime.end : null;
            await observe(sid, "post_tool_failure", {
              tool_name: toolName,
              call_id: callId,
              tool_input: safeSlice(st.input, 4000),
              tool_output: safeSlice(st.error, 8000),
              duration_ms: startTime != null && endTime != null ? endTime - startTime : null
            });
          }
          return;
        }
        if (part.type === "step-finish") {
          await observe(sid, "step_finish", {
            messageID: part.messageID,
            reason: part.reason ?? null,
            cost: part.cost ?? 0,
            input_tokens: part.tokens?.input ?? 0,
            output_tokens: part.tokens?.output ?? 0,
            reasoning_tokens: part.tokens?.reasoning ?? 0
          });
          return;
        }
        if (part.type === "reasoning") {
          await observe(sid, "reasoning", {
            messageID: part.messageID,
            text: safeSlice(part.text, 4000)
          });
          return;
        }
        if (part.type === "file") {
          const filename = part.filename || part.url || null;
          if (filename)
            stashFor(sid).add(filename);
          return;
        }
        if (part.type === "patch") {
          await observe(sid, "patch_applied", {
            messageID: part.messageID,
            hash: part.hash,
            files: part.files || []
          });
          return;
        }
        if (part.type === "compaction") {
          await observe(sid, "compaction_event", {
            messageID: part.messageID,
            auto: part.auto ?? false
          });
          return;
        }
        if (part.type === "agent") {
          await observe(sid, "agent_selected", {
            messageID: part.messageID,
            name: part.name
          });
          return;
        }
        if (part.type === "retry") {
          await observe(sid, "retry_attempt", {
            messageID: part.messageID,
            attempt: part.attempt,
            error: safeSlice(part.error, 2000)
          });
          return;
        }
      }
      if (type === "file.edited") {
        const sid = props.sessionID || activeSessionId;
        if (sid && typeof props.file === "string" && props.file.length > 0) {
          const stash = stashFor(sid);
          stash.add(props.file);
          if (stash.size > MAX_STASHED_FILES) {
            const keep = [...stash].slice(-MAX_STASHED_FILES);
            stash.clear();
            for (const f of keep)
              stash.add(f);
          }
        }
      }
      if (type === "permission.updated") {
        const sid = props.sessionID || activeSessionId;
        if (!sid)
          return;
        await observe(sid, "notification", {
          notification_type: "permission_prompt",
          permission: props.type || "unknown",
          pattern: Array.isArray(props.pattern) ? props.pattern.join(", ") : props.pattern || "",
          tool_call_id: props.callID || null,
          title: props.title || props.type || "",
          metadata: props.metadata || {}
        });
      }
      if (type === "permission.replied") {
        const sid = props.sessionID || activeSessionId;
        if (!sid)
          return;
        await observe(sid, "permission_replied", {
          permission_id: props.permissionID || props.requestID || "",
          response: props.response || props.reply || ""
        });
      }
      if (type === "todo.updated") {
        const sid = props.sessionID || activeSessionId;
        const todos = Array.isArray(props.todos) ? props.todos.slice(0, 100) : [];
        if (!sid || todos.length === 0)
          return;
        const completed = todos.filter((t) => t.status === "completed");
        const active = todos.filter((t) => t.status !== "completed");
        await observe(sid, "task_completed", {
          completed: completed.map((t) => ({ content: t.content, priority: t.priority })),
          in_progress: active.map((t) => ({ content: t.content, priority: t.priority })),
          total: todos.length
        });
      }
      if (type === "command.executed") {
        const sid = props.sessionID || activeSessionId;
        if (sid) {
          await observe(sid, "command_executed", {
            name: props.name,
            arguments: props.arguments || ""
          });
        }
      }
    },
    "chat.message": async (input, output) => {
      const sid = input.sessionID || activeSessionId;
      if (!sid)
        return;
      const parts = output.parts || [];
      const files = parts.filter((p) => p.type === "file").map((p) => p.filename || p.url).filter(Boolean);
      for (const f of files) {
        const stash = stashFor(sid);
        stash.add(f);
        if (stash.size > MAX_STASHED_FILES) {
          const keep = [...stash].slice(-MAX_STASHED_FILES);
          stash.clear();
          for (const k of keep)
            stash.add(k);
        }
      }
      const textParts = parts.filter((p) => p.type === "text" && !p.synthetic && !p.ignored);
      const userText = textParts.map((p) => p.text || "").join(`
`);
      await observe(sid, "prompt_submit", {
        agent: input.agent ?? null,
        model: input.model ?? null,
        variant: input.variant ?? null,
        prompt: userText.slice(0, 8000),
        files: files.slice(0, 20),
        parts_summary: parts.map((p) => p.type).filter(Boolean)
      });
    },
    "chat.params": async (input, output) => {
      if (!input.model || !output)
        return;
      const sid = input.sessionID || activeSessionId;
      if (!sid)
        return;
      await observe(sid, "llm_params", {
        agent: input.agent,
        model: `${input.model.providerID}/${input.model.id}`,
        provider_url: input.model.api?.url ?? null,
        temperature: output.temperature,
        topP: output.topP,
        max_output_tokens: input.model.limit?.output ?? null,
        context_limit: input.model.limit?.context ?? null,
        cost_1k_input: input.model.cost?.input ?? 0,
        cost_1k_output: input.model.cost?.output ?? 0
      });
    },
    "tool.execute.before": async (input, output) => {
      if (!FILE_TOOLS.has(input.tool))
        return;
      const sid = input.sessionID || activeSessionId;
      if (!sid)
        return;
      const args = output.args;
      if (!args)
        return;
      const stash = stashFor(sid);
      for (const fp of extractFilePaths(args)) {
        stash.add(fp);
      }
      if (stash.size > MAX_STASHED_FILES) {
        const keep = [...stash].slice(-MAX_STASHED_FILES);
        stash.clear();
        for (const f of keep)
          stash.add(f);
      }
    },
    "experimental.chat.system.transform": async (input, output) => {
      const sid = input.sessionID || activeSessionId;
      if (!sid)
        return;
      if (!contextInjectedSessions.has(sid)) {
        if (!Array.isArray(output.system))
          return;
        output.system.push(AGENTMEMORY_INSTRUCTIONS);
        let ctx2 = startContextCache.get(sid);
        if (typeof ctx2 !== "string" || ctx2.length === 0) {
          const result = await postJson("/context", {
            sessionId: sid,
            project: projectPath
          });
          ctx2 = result?.context;
        } else {
          startContextCache.delete(sid);
        }
        if (typeof ctx2 === "string" && ctx2.length > 0) {
          output.system.push(ctx2);
        }
        contextInjectedSessions.add(sid);
      }
      const stash = stashFor(sid);
      if (stash.size === 0)
        return;
      const files = [...stash].slice(0, 10);
      const enrichResult = await postJson("/enrich", {
        sessionId: sid,
        files,
        toolName: "enrich_inject"
      });
      const enrichCtx = enrichResult?.context;
      if (typeof enrichCtx === "string" && enrichCtx.length > 0) {
        if (Array.isArray(output.system)) {
          output.system.push(enrichCtx);
        }
        for (const f of files)
          stash.delete(f);
      }
    },
    "experimental.session.compacting": async (input, output) => {
      const sid = input.sessionID || activeSessionId;
      if (!sid)
        return;
      const result = await postJson("/context", {
        sessionId: sid,
        project: projectPath
      });
      const ctx2 = result?.context;
      if (typeof ctx2 === "string" && ctx2.length > 0) {
        if (Array.isArray(output.context)) {
          output.context.push(ctx2);
        }
      }
    },
    config: async (input) => {
      const payload = {
        theme: input.theme ?? null,
        model: input.model ?? null,
        autoupdate: input.autoupdate ?? null,
        agents: typeof input.agent === "object" && input.agent !== null && !Array.isArray(input.agent) ? Object.keys(input.agent) : Array.isArray(input.agent) ? input.agent : [],
        mcp_servers: typeof input.mcp === "object" && input.mcp !== null && !Array.isArray(input.mcp) ? Object.keys(input.mcp) : Array.isArray(input.mcp) ? input.mcp : [],
        providers: typeof input.provider === "object" && input.provider !== null && !Array.isArray(input.provider) ? Object.keys(input.provider) : Array.isArray(input.provider) ? input.provider : [],
        permission: input.permission ?? null
      };
      if (activeSessionId) {
        await observe(activeSessionId, "config_loaded", payload);
      } else {
        pendingConfig = payload;
      }
    }
  };
};
var agentmemory_capture_default = AgentmemoryCapturePlugin;
export {
  agentmemory_capture_default as default,
  AgentmemoryCapturePlugin
};
