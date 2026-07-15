# Echo Kickoff — Final Build Manifest

Date: 2026-07-15 21:39 +06

## Source

- Project: Echo Kickoff
- Engine: Godot 4.7.stable.official
- Renderer: Compatibility / `gl_compatibility`
- Language/runtime: GDScript only
- Source baseline before final release metadata: `2fd0821`
- Feature state: feature-frozen; final QA/build packaging only

## Release artifacts

### Web export

Directory: `build/final/web/`

Files:

| File | Size |
|---|---:|
| `index.html` | 5,442 bytes |
| `index.js` | 279,815 bytes |
| `index.pck` | 499,876 bytes |
| `index.wasm` | 39,509,339 bytes |
| `index.png` | 21,443 bytes |
| `index.icon.png` | 80,708 bytes |
| `index.apple-touch-icon.png` | 19,915 bytes |
| `index.audio.worklet.js` | 7,298 bytes |
| `index.audio.position.worklet.js` | 2,973 bytes |

Export command:

```bash
godot --headless --path . --export-release "Web" build/final/web/index.html
```

### Windows export

Directory: `build/final/windows/`

Files:

| File | Size |
|---|---:|
| `echo-kickoff.exe` | 109,103,104 bytes |
| `echo-kickoff.pck` | 499,876 bytes |

Export command:

```bash
godot --headless --path . --export-release "Windows Desktop" build/final/windows/echo-kickoff.exe
```

Static verification:

- `echo-kickoff.exe`: PE32+ GUI x86-64 Windows executable.
- `echo-kickoff.pck`: Godot data pack present beside the executable.

### itch.io Web ZIP

File: `build/final/package/echo-kickoff-web-itch.zip`

Size: 10,680,463 bytes

ZIP root contents:

```text
index.apple-touch-icon.png
index.audio.position.worklet.js
index.audio.worklet.js
index.html
index.icon.png
index.js
index.pck
index.png
index.wasm
```

The ZIP contains only Web export files at root. It does not include source files, project files, docs, tests, tools, debug scenes, Git metadata, or macOS `.DS_Store`.

### SHA-256 checksums

File: `build/final/SHA256SUMS.txt`

```text
690e21a00bd830449b2c64b514af5e7f419ca8a718e610e9dedf49594f4584f8  build/final/web/index.apple-touch-icon.png
be33985bc7160d6bf9646f259cd86b259cd67b02ccb297ee5c44f8ac84327bc8  build/final/web/index.audio.position.worklet.js
5b476a9c9ce642c0ee4256436d1bc31d9c38f868aca0f9a8e2a57c18d2dec2a3  build/final/web/index.audio.worklet.js
0c7b3110f1575ba2c80883a6519f3ea7c796afc65aaf93c5b997f797b435b0c3  build/final/web/index.html
ba7c9facf265cca6cb2a8d69984be1c724a44d561d76373f70b6aed1664742be  build/final/web/index.icon.png
68586d6daafc93c6e697b3fb258976874aa7459b8931165ebb1dc3c9614cc42c  build/final/web/index.js
42f17a0ee46543696a06453326940b16a2743c2bf24c1d7acfa41d99522d1d4a  build/final/web/index.pck
3cb4495c0b98dfbe4b663cbf2b6836473572339beb66d902367893162a70be0e  build/final/web/index.png
7eda98958eb09135a1acb54a4323a00b1a55af1997f15fa1cdc2b93e3df46656  build/final/web/index.wasm
6b05da3f244df7c249b928f464066c88c729aa1bc100f086343746eb13d64f6d  build/final/windows/echo-kickoff.exe
42f17a0ee46543696a06453326940b16a2743c2bf24c1d7acfa41d99522d1d4a  build/final/windows/echo-kickoff.pck
3781e455d86dc6faf1dfd1413d23054dfea9be147d12fb658b7b94cb29b0fab9  build/final/package/echo-kickoff-web-itch.zip
```

## Packaging checks

- Web export filename is `index.html`; generated sibling files were not renamed after export.
- Itch ZIP root contains `index.html`.
- Itch ZIP source exclusion check passed.
- Release PCK debug-resource checks passed for:
  - `tests/`
  - `tools/`
  - `marketing/`
  - `scenes/debug/`
  - `scripts/debug/`
  - `sector_00_test`
  - `sector_00_visual`

