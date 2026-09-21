import { validateProjectQuestion } from "./project_question.ts";

function assert(value: unknown): asserts value {
  if (!value) throw new Error("Assertion failed");
}

Deno.test("project question accepts bounded evidence with sequential source IDs", () => {
  const result = validateProjectQuestion({ question: " 登入何時交付？ ", evidence: JSON.stringify({ sources: [{ id: "S1", text: "尚待確認" }] }) });
  assert(result?.question === "登入何時交付？");
});

Deno.test("project question rejects malformed, empty and oversized inputs", () => {
  for (const input of [null, {}, { question: "x", evidence: "bad json" },
    { question: "x", evidence: JSON.stringify({ sources: [] }) },
    { question: "x", evidence: JSON.stringify({ sources: [{ id: "S99", text: "內容" }] }) },
    { question: "x", evidence: JSON.stringify({ sources: [{ id: "S1", text: "" }] }) },
    { question: "x".repeat(2001), evidence: "{}" },
    { question: "x", evidence: "x".repeat(48001) },
  ]) assert(validateProjectQuestion(input) === null);
});
