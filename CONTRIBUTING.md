# Contributing

## Development Setup

Use Windows x64, Python 3.12 and Git. From the repository root:

```powershell
cd native
.\install-environment.ps1
.\build.ps1
```

Run `package.ps1`, `package-single.ps1` and `package-source.ps1` before preparing a release. Keep game-build-specific addresses and signatures in `analysis/hades_trainer/hades_runtime_profile.json` rather than scattering them through UI code.

## Pull Requests

- Keep changes scoped and describe the tested Hades build.
- Include verification steps for runtime behavior changes.
- Preserve Chinese and English labels for new UI controls.
- Update `THIRD_PARTY_NOTICES.md` when adding or upgrading a dependency.
- Do not commit build output, game binaries, save files, IDA databases or release archives.
