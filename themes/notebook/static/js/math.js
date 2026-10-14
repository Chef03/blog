document.addEventListener("DOMContentLoaded", () => {
  const content = document.getElementById("article-content");
  if (!content || typeof renderMathInElement !== "function") return;
  renderMathInElement(content, {
    delimiters: [
      { left: "$$", right: "$$", display: true },
      { left: "\\[", right: "\\]", display: true },
      { left: "\\(", right: "\\)", display: false },
      { left: "$", right: "$", display: false },
    ],
    throwOnError: false,
    strict: "warn",
    trust: false,
  });
});
