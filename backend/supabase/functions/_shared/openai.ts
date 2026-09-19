import { HttpError, requiredEnv } from "./http.ts";

type CompletionOptions = {
  system: string;
  user: string;
  temperature?: number;
  jsonObject?: boolean;
};

export async function complete(options: CompletionOptions): Promise<string> {
  const response = await fetch("https://api.openai.com/v1/chat/completions", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${requiredEnv("OPENAI_API_KEY")}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      model: Deno.env.get("OPENAI_CHAT_MODEL")?.trim() || "gpt-4o-mini",
      temperature: options.temperature ?? 0.3,
      messages: [
        { role: "system", content: options.system },
        { role: "user", content: options.user },
      ],
      ...(options.jsonObject
        ? { response_format: { type: "json_object" } }
        : {}),
    }),
  });
  if (!response.ok) {
    console.error("OpenAI request failed", response.status, await response.text());
    throw new HttpError(502, "AI_PROVIDER_FAILED");
  }
  const data = await response.json();
  const content = data?.choices?.[0]?.message?.content;
  if (typeof content !== "string" || content.trim() === "") {
    throw new HttpError(502, "AI_PROVIDER_EMPTY_RESPONSE");
  }
  return content.trim();
}

export function clipped(value: unknown, max: number): string {
  return typeof value === "string" ? value.trim().slice(0, max) : "";
}

export function transcriptText(value: unknown, maxLines = 400): string {
  if (!Array.isArray(value)) return "";
  return value.slice(-maxLines).map((item) => {
    const speaker = clipped(item?.speaker, 80) || "未知";
    const text = clipped(item?.text, 4000);
    const startMs = Number.isFinite(item?.startMs) ? Number(item.startMs) : 0;
    const minutes = Math.floor(startMs / 60000).toString().padStart(2, "0");
    const seconds = Math.floor(startMs / 1000 % 60).toString().padStart(2, "0");
    return `[${minutes}:${seconds}] ${speaker}：${text}`;
  }).filter((line) => !line.endsWith("：")).join("\n");
}
