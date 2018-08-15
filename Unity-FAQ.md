---
title: Unity FAQ
description: Stuff I have learned while working with Unity
---

* Table of Contents
{:toc}
##### How to find all objects in a scene

To find all ScriptableObject instances in a scene, use `Resources.FindObjectsOfTypeAll<T>()`. It is an expensive operation, so only use it sparingly.

##### What is a CustomAsset?

A CustomAsset is a free Askowl package that is a ScriptableObject with benefits. It provides persistence, events on data change and multiple memberships. See http://askowl.net/customassets for more details.

##### Loading Scriptable Objects/Custom Assets

A ScriptableObject or CustomAsset does not load, even if referenced, if it does not contain filled data. For custom assets, add text to the ***Description*** field for `Trigger` instances.

##### Markless Augmented Reality

Unity3D has all the tools built-in for Markerless Augmented Reality on Android or iOS - Camera, gyroscope, compass and GPS modules.

##### PlayMode Testing

PlayMode TestRunner works well. You can load a scene and use all the same built-in Unity3D methods to monitor what is happening. Then it is just a matter of using Assert to check for problems.

##### Caching for Performance

Cache everything you can. CPU and GPU are more limiting factors than memory on modern phones.

##### Package Management

Unity 2018.1 includes a package manager, selected from the *Windows* menu. Currently, it is only for Unity components, but there is a promise that we will eventually be able to use it for the Unity *Asset Store*. I can't wait for the package dependency management.

##### C# Structs are Different to Classes

Structs, like ints and floats, are passed by value. Passing a struct to a method duplicates the contents, and again if used as the return value. So, don't use them for large amounts of data. The copy is shallow, so references to class Instances are not expensive. You can change the contents of a struct, but when you return all the changes disappear. It is not the case if you change data in a class instance that is inside the struct.

##### Coroutine Overhead

When you enter `yield return myCoroutine()`, Unity is pausing the current coroutine and starting a new one. It is the same as `yield return StartCoroutine(myCoroutine())`.

##### Quaternions

Everyone says that you don't need to understand quaternions to use them. True until you hit the wall and need to do something the standard library doesn't provide. If you find yourself converting to Euler angles and back to Quaternions then it is time to work out how to make those unreal numbers dance.

##### Lerp and Slerp Performance

Everywhere you go there are warnings about how slow Slerp is when compared with Lerp. Indeed, the published algorithms support this. Slerp has many trigonometric functions while Lerp survives on multiply and divide. When I ran a test on my Mac, Slerp was less than 15% slower. How can this be? It may be that Unity is using an augmented Lerp when it is applicable. It could also be that an Intel Core i7 has faster maths for trigs than anticipated.