const esbuild = require("esbuild");
const ElmPlugin = require("esbuild-plugin-elm");

const args = process.argv.slice(2);
const watch = args.includes("--watch");
const deploy = args.includes("--deploy");

const baseOpts = {
  entryPoints: ["src/wordle.js"],
  bundle: true,
  outdir: "../js",
};

if (watch) {
  esbuild
    .context({
      ...baseOpts,
      plugins: [
        ElmPlugin({
          debug: true,
          clearOnWatch: true,
        }),
      ],
    })
    .then((ctx) => {
      ctx.watch();
    })
    .catch((_e) => {
      process.exit(1);
    });
} else if (deploy) {
  esbuild.build({
    ...baseOpts,
    plugins: [ElmPlugin({ optimize: true })],
  });
} else {
  esbuild.build({
    ...baseOpts,
    plugins: [ElmPlugin()],
  });
}
