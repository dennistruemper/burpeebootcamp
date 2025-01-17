const fs = require("fs");
const path = require("path");

const filePaths = [
  path.join(__dirname, "..", "public", "serviceWorker.js"),
  path.join(__dirname, "..", "elm-pkg-js", "interop.js"),
];

filePaths.forEach((filePath) => {
  fs.readFile(filePath, "utf8", (err, data) => {
    if (err) {
      console.error("Error reading file:", err);
      return;
    }

    const versionRegex = /const version = "v(\d+)";/;
    const match = data.match(versionRegex);

    if (match) {
      const currentVersion = parseInt(match[1], 10);
      const newVersion = currentVersion + 1;
      const updatedData = data.replace(
        versionRegex,
        `const version = "v${newVersion}";`
      );

      fs.writeFile(filePath, updatedData, "utf8", (writeErr) => {
        if (writeErr) {
          console.error("Error writing file:", writeErr);
        } else {
          console.log(`Version updated to v${newVersion}`);
        }
      });
    } else {
      console.error("Cache version not found in the file");
    }
  });
});
