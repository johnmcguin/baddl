// const esbuild = require("esbuild");
// import esbuild from "esbuild";
//
const esbuild = require("esbuild");
// const ElmPlugin = require("esbuild-plugin-elm");
// import ElmPlugin from "esbuild-plugin-elm";
const ElmPlugin = require("esbuild-plugin-elm");

esbuild
  .build({
    entryPoints: ["src/wordle.js"],
    bundle: true,
    outdir: "../js",
    // watch: process.argv.includes("--watch"),
    plugins: [
      ElmPlugin({
        debug: true,
        clearOnWatch: true,
      }),
    ],
  })
  .catch((_e) => process.exit(1));
