How to find all objects in a scene
To find all ScriptableObject instances in a scene, use `Resources.FindObjectsOfTypeAll<T>()`. It is an expensive operation, so only use it sparingly.

What is a CustomAsset?
A CustomAsset is a free Askowl package that is a ScriptableObject with benefits. It provides persistence, events on data change and multiple memberships. See http://customassets.marrington.net for more details.

A ScriptableObject or CustomAsset does not load, even if referenced, if it does not contain filled data. For custom assets, add text to the ***Description*** field for `Trigger` instances.
* Unity3D has all the tools built-in for Markerless Augmented Reality on Android or iOS - Camera, gyroscope, compass and GPS modules.
* PlayMode TestRunner works well. You can load a scene and use all the same built-in Unity3D methods to monitor what is happening. Then it is just a matter of using Assert to check for problems.
* Cache everything you can. CPU and GPU are more limiting factors than memory on modern phones.
* Unity 2018.1 includes a package manager, selected from the *Windows* menu. Currently, it is only for Unity components, but there is a promise that we will eventually be able to use it for the Unity *Asset Store*. I can't wait for the package dependency management.