---
title: Askowl Build for Unity3D
description: Environment Building Aids for Unity3D
---
* Table of Contents
{:toc}

> Read the code in the Examples Folder.

# DefineSymbols

The only way to compile code that relies on a library that may not exists is to use the preprocessor. Since we will know the availability of a package, we can tell the compiler.

To do this, create a class in a ***Editor*** directory and have it initialise on load. Have it inherit from ```AddDefineSymbols```. In the static constructor run your tests and add or remove define symbols as needed.

## Symbol Definition Control
There are three define symbol methods:

1. `AddDefines(string defines);`
2. `RemoveDefines(string defines);`
3. `AddOrRemoveDefines(bool addDefines, string defines);`

The last method looks unwieldy, but it is valuable for controlling compile-time actions that are build target dependent.

## HasFolder
Provide the `HasFolder(string folder)` with the string representation of a folder under ***Assets***. `HasFolder` is the easiest way to check *unitypackage* existence.

## Target
Even if a *unitypackage* exists, the code may not apply to the target platform. `Target` takes a list of parameters and returns true if we are compiling for one of them.

Possible targets are `Android`, `iOS`, `Linux`, `Linux64`, `LinuxUniversal`, `N3DS`, `OSX`, `PS4`, `PSP2`, `Switch`, `Tizen`, `tvOS`, `WSAPlayer`, `WebGL`, `WiiU`, `Windows`, `Windows64` and `XboxOne`.

```c#
if (Target(iOS, Android) {...}
```

## Example
```c#
[InitializeOnLoad]
public class MyDependent : AddDefineSymbols {
  static MyDefinitions() {
    bool ok = HasFolder("My-Unity-Package") || Target(iOS, Android);
    AddOrRemoveDefines(ok, "myUnityPackage;myUnityPackageAvailable");
  }

class myUnityPackageImplementation : MyUnityPackageInterface {
  #if myUnityPackage
    // do something, so the system uses this version of the interface
  #else
    static myUnityPackageImplementation() {
      Debug.LogWarning("Please install 'whatever.unitypackage' from the store");
    }
  #endif
}
```

`AskowlDecoupler` uses this technology. The implementation only activates for installed external packages.

# Pre/Post Process Build
When building for different platforms, it is often necessary to tweak native configurations either before or after the build. All the tweaks are optional. Look to ***Askowl-Lib/Resources/PostProcessBuildDefault*** in the Unity Editor for the options you can change.

## Pre-Process Build
### Android - Enable Multidex
Almost any Unity3D game of any size will have more than 64,000 public methods. I know, this sounds crazy. It's all those packages you have imported. You could enable ***Proguard***. Apart from obfuscating your app it also attempts to remove all the functions not called. It is rarely fully automatic since it cannot efficiently deal with reflection. Multidex does not have that problem. It does make your app larger.

## Post-Process Build
### iOS - Remove Notifications
If your app does not use Push Notifications, then you can check this option to remove the build warning.

### iOS - Plist Entries
iOS will not be accepted if Apple does not find particular *plist* entries. Unity3D generates most of them, but occasionally they get out of sync. As of 2017, the ***NSCalendarsUsageDescription*** was missing. Add others as you need them.
