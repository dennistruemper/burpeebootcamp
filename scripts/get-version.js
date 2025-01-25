const fs = require("fs");
const path = require("path");

function getCurrentVersion() {
  const serviceWorkerPath = path.join(
    __dirname,
    "..",
    "public",
    "serviceWorker.js"
  );
  const content = fs.readFileSync(serviceWorkerPath, "utf8");
  const match = content.match(/const version = "v(\d+)";/);
  if (!match) {
    throw new Error("Version not found in service worker");
  }
  return match[1];
}

module.exports = { getCurrentVersion };
