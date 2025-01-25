const fs = require("fs");
const path = require("path");

const filePaths = [
  path.join(__dirname, "..", "public", "serviceWorker.js"),
  path.join(__dirname, "..", "elm-pkg-js", "interop.js"),
];

const htmlPaths = [
  path.join(__dirname, "..", "head.html"),
  path.join(__dirname, "..", "landingpage", "index.html"),
];

// Update HTML references to CSS files
const updateCssFiles = (newVersion) => {
  // Update HTML files to reference new CSS version
  htmlPaths.forEach((htmlPath) => {
    fs.readFile(htmlPath, "utf8", (err, data) => {
      if (err) {
        console.error(`Error reading HTML file ${htmlPath}:`, err);
        return;
      }

      // Different patterns for different files
      let updatedData;
      if (htmlPath.includes("landingpage")) {
        // For landingpage/index.html (relative path)
        updatedData = data.replace(
          /<link rel="stylesheet" href="styles[^"]*\.css"/,
          `<link rel="stylesheet" href="styles.v${newVersion}.css"`
        );
      } else {
        // For head.html (absolute path)
        updatedData = data.replace(
          /<link rel="stylesheet" href="\/styles[^"]*\.css"/,
          `<link rel="stylesheet" href="/styles.v${newVersion}.css"`
        );
      }

      fs.writeFile(htmlPath, updatedData, "utf8", (writeErr) => {
        if (writeErr) {
          console.error(`Error updating HTML file ${htmlPath}:`, writeErr);
        } else {
          console.log(`Updated CSS reference in ${htmlPath}`);
        }
      });
    });
  });
};

// Read and update version in files
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
          updateCssFiles(newVersion);
        }
      });
    } else {
      console.error("Cache version not found in the file");
    }
  });
});
