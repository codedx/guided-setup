## Overview

This repository contains a framework for installing an application on a Kubernetes cluster using a setup wizard based on a directed graph. It depends on the cross-platform [PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/overview) software, which runs on Windows, Linux, and macOS.

## Reference Implementation

For an example of how to use the guided-setup, refer to the reference implementation at [demo](demo).

## Installation

You can obtain the latest guided-setup PowerShell module from the [PowerShell Gallery](https://www.powershellgallery.com/packages?q=guided-setup). You can install the module by running the following commands:

```
$ pwsh
PS /> Install-Module guided-setup
```

You can view installed modules with this command:

```
PS /> Get-InstalledModule
```

## Uninstallation

You can uninstall the guided-setup module with this command:

```
PS /> Uninstall-Module guided-setup
```
