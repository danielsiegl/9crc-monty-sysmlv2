# 9C RC Monty Sysmlv2 Example Models!

This repository contains SysML v2 example models of selected subsystems of the 9C RC Monty, a 4WS MOA radio-controlled rock crawler, rather than a complete model of the vehicle. So they are from a real development effort on a real product and not just syntetic.

https://9crc.com/


![9C_02](/images/9C_02.png)

## Validating the models

The models are checked with [sysml-toolkit](https://github.com/Open-MBEE/sysml-toolkit) (`sysmlv2`) against the [SysML v2 standard library](https://github.com/Systems-Modeling/SysML-v2-Release) (release `2026-08`).

### In CI

The [SysML v2 Validation](.github/workflows/sysmlv2validation.yml) workflow runs on every push and pull request. It uses the latest sysml-toolkit release and validates, evaluates and exports all `.sysml` files as one model. The results appear in the run's job summary, and the full reports and the exported JSON model are uploaded as workflow artifacts. If any step fails, the run fails.

### Locally (Windows / PowerShell)

```powershell
.\validate.ps1                 # validate all .sysml files (sysmlv2 check)
.\validate.ps1 eval --all      # pass any other sysmlv2 command through
.\validate.ps1 -Update         # re-download the latest sysml-toolkit, then validate
```

On the first run the script downloads the latest Windows release of sysml-toolkit (it verifies the SHA256 checksum) and the SysML v2 standard library into `.bin\`. Later runs reuse them. `.bin\` is git-ignored. Downloading the library requires `git`.

If you change the standard library version, update it in both `validate.ps1` (`$SysmlReleaseVersion`) and the workflow (`SYSML_RELEASE_VERSION`).


