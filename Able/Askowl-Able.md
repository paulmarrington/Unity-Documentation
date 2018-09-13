# [Able - Askowl Base Library Enabler](http://unitydoc.marrington.net/Able)

## Executive Summary

Unity provides lots of great functionality, but there are always more problems than there are solutions. All the solutions documented here were to solve problems in other Askowl libraries. They also stand on their own when simple is not so simple. There are currently four sections for Math, Data, Text and Unity. There is a lot here. All I can suggest is that you browse the table of contents.

* Table of Contents
{:toc}

> Read the code in the Examples Folder and run the Example scene

## Introduction

## Maths functions

### Clock.cs - time and date conversions

#### Epoch Time

Epoch time was invented by the early Unix creators to represent time as seconds since the start of 1970 in a 32-bit integer for fast calculations. In this form, it wraps around on 2038. It also suffered some inaccuracy because it did not account for leap seconds. This conversion is not 2038 limited as it uses doubles. Leap seconds will only be an issue if you are using dates each side of one - an unlikely event with minor implications.

```c#
DateTime now          = DateTime.Now;
double   epochTimeNow = Clock.EpochTimeNow;
double   epochTime    = Clock.EpochTimeAt(now);
AssertAlmostEqual(epochTime, epochTimeNow);

DateTime later          = now.AddDays(1);
double   epochTimeLater = Clock.EpochTimeAt(later);
AssertAlmostEqual(24 * 60 * 60, epochTimeLater - epochTimeNow);

var diff = later.Subtract(Clock.FromEpochTime(epochTimeLater));
AssertAlmostEqual(diff.TotalSeconds, 0);
```

##### double EpochTimeNow;

Epoch time is always UTC.

##### double EpochTimeAt(DateTime when);

Convert local time to UTC if necessary then translate to epoch time. Unlike Unix Epoch time, leap seconds are accounted for.

##### DateTime FromEpochTime(double epochTime);

Convert back from Epoch UTC to local time, C# style.

### Compare.cs - equality and almost equality

#### AlmostEqual for Floating Point

Comparing floating point numbers can be a hit or miss affair. Every mathematical operation is subject to rounding to fit into the number of bits. A single precision 32-bit float has around 7 digits of accuracy.  Even trivial calculations may not compare equal.

Enter `Compare.AlmostEqual`. You can specify the minimum change or use the defaults of 0.001 for single precision and 0.00001 for doubles.

```c#
IsFalse(Compare.AlmostEqual(a: 1.1f, b: 1.2f, minimumChange: 0.1f));
IsTrue(Compare.AlmostEqual(a: 1.1f,  b: 1.2f, minimumChange: 0.11f));

IsFalse(Compare.AlmostEqual(a: 1.1f, b: 1.11f));
IsTrue(Compare.AlmostEqual(a: 1.1f,  b: 1.0999f));

IsFalse(Compare.AlmostEqual(a: 103.11, b: 104, minimumChange: 0.5));
IsTrue(Compare.AlmostEqual(a: 103.11,  b: 104, minimumChange: 0.9));

IsFalse(Compare.AlmostEqual(a: 123.45678, b: 123.45679));
IsTrue(Compare.AlmostEqual(a: 123.456789, b: 123.45679));
```

#### AlmostEqual for Integers

Integers don't suffer from rounding problems. Sometimes it is useful to see if two values are close.

```c#
IsFalse(Compare.AlmostEqual(a: 123L, b: 133L, minimumChange: 10L));
IsTrue(Compare.AlmostEqual(a: 123L,  b: 133L, minimumChange: 11L));

IsFalse(Compare.AlmostEqual(a: 123L, b: 125L));
IsFalse(Compare.AlmostEqual(a: 123L, b: 121L));
IsTrue(Compare.AlmostEqual(a: 123L,  b: 124L));
IsTrue(Compare.AlmostEqual(a: 123L,  b: 122L));

IsFalse(Compare.AlmostEqual(a: 1, b: 4, minimumChange: 2));
IsTrue(Compare.AlmostEqual(a: 1,  b: 3, minimumChange: 4));

IsFalse(Compare.AlmostEqual(a: 1, b: 4));
IsTrue(Compare.AlmostEqual(a: 1,  b: 2));
```

#### IsDigitsOnly

Check the contents of a string and return true if it only has digits.

```
Assert.IsTrue(Compare.isDigitsOnly("123987654"));

Assert.IsFalse(Compare.isDigitsOnly("12no shoe"));
Assert.IsFalse(Compare.isDigitsOnly("1.4"));
Assert.IsFalse(Compare.isDigitsOnly("-66"));
Assert.IsFalse(Compare.isDigitsOnly(""));
```

### [ExponentialMovingAverage.cs](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average)

***<u>From Wikipedia</u>***:

> An **exponential moving average (EMA)**, also known as an **exponentially weighted moving average (EWMA)**,[[5\]](https://en.wikipedia.org/wiki/Moving_average#cite_note-5) is a first-order [infinite impulse response](https://en.wikipedia.org/wiki/Infinite_impulse_response) filter that applies weighting factors which decrease [exponentially](https://en.wikipedia.org/wiki/Exponential_decay). The weighting for each older [datum](https://en.wikipedia.org/wiki/Data) decreases exponentially, never reaching zero. The graph at right shows an example of the weight decrease.

 ***<u>From Me (Paul Marrington):</u>***

> An **exponential moving average** is a way to calculate an average where old values have less impact on the average than more recent ones.

It is most often used in financial calculations, but I use it mainly for IoT. Many devices can read wildly until the settle down. Then real-world interactions make then inaccurate again. A class is the compass or magnetometer. Walk past a mass of steel and they will be attracted - just like an engineer. Using an EMA and these variations will be dampened. EMA is also useful when merging IoT data.

#### EMA Initialisation

The purest form is to create a new EMA object without parameters.

```c#
var ema = new ExponentialMovingAverage(); // lookback defaults to 8
```

As the comment says, the average is over the last 8 values plus the new one. You can set your own.

```c#
var ema = new ExponentialMovingAverage(lookback: 50);
```

The lookback value is application specific. Ask yourself how many data points back is the information irrelevant to the current value. If you take one reading a second and any reading over 15 seconds old has no value, set lookback to 15.

#### EMA Average Value

If you don't make `Average` calls at consistent time intervals then you will need to consider other methods to make the values equally spaced.

```c#
AreEqual(expected: 1f,      actual: ema.Average(value: 1));
AreEqual(expected: 2.6f,    actual: ema.Average(value: 5));
AreEqual(expected: 2.76f,   actual: ema.Average(value: 3));
AreEqual(expected: 4.056f,  actual: ema.Average(value: 6));
AreEqual(expected: 4.0336f, actual: ema.Average(value: 4));
```

#### EMA Average Angle

Using EMA with angles in degrees is the same except that the result is normalised to be between -180 and +180 degrees.

```c#
AreEqual(expected: -10f,       actual: ema.AverageAngle(degrees: -10));
AreEqual(expected: -5.555555f, actual: ema.AverageAngle(degrees: 10));
AreEqual(expected: -5.432098f, actual: ema.AverageAngle(degrees: -5));
AreEqual(expected: -3.113854f, actual: ema.AverageAngle(degrees: 5));
AreEqual(expected: -3.088552f, actual: ema.AverageAngle(degrees: 357));
AreEqual(expected: -1.513316f, actual: ema.AverageAngle(degrees: 364));
```

### Geodetic.cs - distances and bearings

> **Geodesy**: The branch of mathematics dealing with the shape and area of the earth or substantial portions of it.
>
> **Origin**: late 16th century: from modern Latin geodaesia, from Greek geōdaisia, from gē ‘earth’ + daiein ‘divide’.
>
> https://en.wikipedia.org/wiki/Geodesy
> https://www.movable-type.co.uk/scripts/latlong.html

> **Paul's Definition**: Calculations of distances and bearings of and between two points on the earth's surface and accounting for the curvature of the earth.

#### Coordinates Data Structure

Another data structure that contain coordinates. In the end, it is more efficient to have separate definitions than it is to burden one definition with lots of irrelevant data. It is particularly poignant when we are dealing with pass-by-value.

In this world-view, coordinates use 64-bit double floating points for accuracy and know whether they are degrees or radians.

```c#
var location = Geodetic.Coords(-27.46850, 151.94379);
var same = Geodetic.Coords(-0.4794157656, 2.65191941345, radians: true);
location.ToRadians();
same.ToDegrees();
Debug.Log(same.ToString()); // -27.46850, 151.94379
```

#### Distance Between Two Points

In the geodetic parlance, the shortest distance between two points is an arc, not a straight line. This is kind of important if you don't want to tunnel through earth and dive under the sea to get anywhere.

`Kilometres(from, to)` uses the Haversine formula to calculate the distance taking into account an approximation of the earth's curvature. For display convenience there is a version, `DistanceBetween(from, to)`, that returns a string that is more friendly than the raw kilometres. If the distance is below one kilometre, it returns the value as a whole number of metres (i.e. 43 m). For distances below ten kilometres, one decimal place is provided (4.7 km). Above the kilometres are whole numbers only (23 km).

#### Bearing from One Point to the Next

If you were hiking, you would take a bearing between yourself and a known landmark and use that bearing to get there.

```c#
var degrees = Geodetic.BearingDegrees(from, to);
var radians = Geodetic.BearingRadians(from, to);
Assert.AreEqual(degrees, Trig.degrees(radians));
```

#### Find One Point from Another

The next navigational trick is to find a destination coordinate when knowing the bearing and distance of that point. Useful if you want to call an air-strike down on an enemy position you are observing.

```c#
Geodetic.Destination(start: here, distanceKm: 1.2, bearingDegrees: 23.4);
```

### Quaternions.cs - adding features

Unity quaternion math focusses on the needs of the game. Great, but there are a few methods needed for augmented reality that are not provided.

#### AroundAxis

Rotate a quaternion around the X, Y or Z axis by the given number of degrees. This is a useful approach for a clock face, a compass or a merry-go-round.

```c#
// ... A
// rotate z axis for magnetic heading
attitude = attitude.AngleAxis(Trig.zAxis, compass.MagneticHeading);
// ... B
```

#### Inverse

An inverse changes the direction of the rotation. If you rotate a quaternion then rotate it again using the inverse then you get back the original quaternion.

```c#
// C ...
mainCamera.transform.localRotation = attitude.Inverse();
```

#### LengthSquared

The concept of length or magnitude for a quaternion has no visual representation when dealing with attitude or rotation. The catch is that most algorithms require unit quaternions - where the length squared approaches one.

#### Normalise

> We can compute a fast 1/sqrt(x) by using a tangent-line approximation to the function. This is like a simple 1-step Newton-Raphson iteration, and by tuning it for our specific case, we can achieve high accuracy for cheap. (A Newton-Raphson iteration is how specialised instruction sets like 3DNow and SSE compute fast 1/sqrt).

|           http://www.cs.uky.edu/~cheng/cs633/quaternion.html |
| -----------------------------------------------------------: |
| **The Inner Product, March 2002<br>**Jonathan Blow ([jon@number-none.com](mailto:jon@number-none.com)) |

This version is on an average 20% faster than `normalised` as provided by Unity.

#### RightToLeftHanded

For rotations, quaternions hold information on the direction in 3 dimensions and the rotation of the object. Think of an aeroplane flying straight in a particular direction. Given a point of reference, you can calculate the angle on the X, Y and Z planes. Now the aeroplane dips it's wing and spins upside-down. The calculations before are the same, but the rotation has changed. Just as the Euler angles define the direction of travel, the sign of the rotation defines which way the aeroplane is spinning.

Two of anything with opposite chirality cannot be superimposed on each other and yet can be otherwise identical. The choice of which rotation direction is positive is arbitrary. The gyroscope used in phones has right-hand chirality, while Unity uses left-handed.

```c#
Quaternion rotateTo = Device.Attitude.RightToLeftHanded(Trig.zAxis);
```

#### RotateBy

Unity is left handed using the Z-axis for the forward direction. The iOS gyroscope, for example, is right-handed. We can reverse the Chirality (a fancy word for handed) by negating the offending axis and W. This effectively reverses the direction of rotation.

```c#
var attitude = GPS.Attitude.RightToLeftHanded(Trig.zAxis);
```

#### SwitchAxis

Different IoT devices define different axes as forward. We need to pivot on the third axis by 90 degrees to correct for the difference. This reverses the chirality, but this function corrects for that.

```c#
// B ...
// Gyro Z axis is Unity camera Y.
attitude.SwitchAxis(pivot: Trig.xAxis)
// ... C
```

### Trig.cs

#### Direction

##### Trig.xAxis, Trig.yAxis and Trig.zAxis

When I prefer to use *X, Y, Z* instead of *right, up, forward* I use Trig.Direction values. These are unit directions with either the X, Y or Z component set 1 one to specify the axis.

##### X, Y and Z

Integers where one is non-zero to define an axis. A direction is also recorded as it can be 1 or -1.

##### Name

The name is a character constant, being 'X', 'Y' or 'Z'. Use it for switch statements where the character means more than using the ordinal value.

##### Ord

Ordinal value - the same as for `Vector3` - X=0, Y=1, Z=2. The values can be access by ordinal value (i.e. Trig.xAxis[0] == 1).

##### Vector

When Unity provided functions want to describe a direction, they use constants inside `Vector3` such as `Vector3.up`. To provide directions as XYZ, use `Trig.Y.Vector`.

##### VectorName

Just for kicks and giggles, you can also retrieve the name of the associated vector `Trig.Y.VectorName == "up"`.

##### OtherAxes

When we use an axis as a pivot, we will want the other axes to work with. This field refers to an array of the other two Directions. `Trig.xAxis.OtherAxes[0] == Trig.yAxis && Trig.xAxis.OtherAxes[1] == Trig.zAxis`.

##### Negative

`Vector3` has the concept of direction where positive is up, and the negative is down, with the same for left and right or forward and back. For `Trig.Direction`, use the unary minus as in `-Trig.xAxis`. OtherAxes for negative directions will themselves be negative. You can check if a direction is negative with `Trig.xAxis.Negative == false`.

Here is a slice of the unit tests for `Trig.xAxis` only.  Use these as a guide for what you can achieve.

```c#
var xAxis = Trig.xAxis;
var yAxis = Trig.yAxis;
var zAxis = Trig.zAxis;

Assert.AreEqual(1,             xAxis.X);
Assert.AreEqual(0,             xAxis.Y);
Assert.AreEqual(0,             xAxis.Z);
Assert.AreEqual(xAxis[0],      xAxis.X);
Assert.AreEqual(xAxis[1],      xAxis.Y);
Assert.AreEqual(xAxis[2],      xAxis.Z);
Assert.AreEqual('X',           xAxis.Name);
Assert.AreEqual("X Axis",      xAxis.ToString());
Assert.AreEqual(0,             xAxis.Ord);
Assert.AreEqual(Vector3.right, xAxis.Vector);
Assert.AreEqual("right",       xAxis.VectorName);
var otherAxes = xAxis.OtherAxes;
Assert.AreEqual(yAxis, otherAxes[0]);
Assert.AreEqual(zAxis, otherAxes[1]);

// Tests for negative
var minusX = -Trig.xAxis;
var minusY = -Trig.yAxis;
var minusZ = -Trig.zAxis;

Assert.IsFalse(xAxis.Negative);
Assert.IsTrue(minusX.Negative);
Assert.AreEqual(-1,           minusX.X);
Assert.AreEqual(0,            minusX.Y);
Assert.AreEqual(0,            minusX.Z);
Assert.AreEqual(minusX[0],    minusX.X);
Assert.AreEqual(minusX[1],    minusX.Y);
Assert.AreEqual(minusX[2],    minusX.Z);
Assert.AreEqual('X',          minusX.Name);
Assert.AreEqual("-X Axis",    minusX.ToString());
Assert.AreEqual(0,            minusX.Ord);
Assert.AreEqual(Vector3.left, minusX.Vector);
Assert.AreEqual("left",       minusX.VectorName);
otherAxes = minusX.OtherAxes;
Assert.AreEqual(minusY, otherAxes[0]);
Assert.AreEqual(minusZ, otherAxes[1]);
```

#### ToRadians

Convert a number in degrees to radians.

```c#
Assert.IsTrue(Compare.AlmostEqual(1.5708, Trig.ToRadians(90)));
```

#### ToDegrees

Convert a value in radians back to degrees. Note the need to reduce accuracy in the comparison due to the calculation.

```c#
Assert.IsTrue(Compare.AlmostEqual(90, Trig.ToDegrees(1.5708), 1e5));
```

#### Relative Position given Distance and Angle or Bearing

Calculate a relative vector in two dimensions give the distance away and the angle or bearing.

##### RelativePositionFromAngle

This is a trigonometric angle where 0 degrees in +X and 90 degrees is East or +1. Increasing angles move the result counter-clockwise.

```c#
expected.Set(3.3f, 0);
actual = Trig.RelativePositionFromBearing(3.3f, Trig.ToRadians(90));
AreEqual(expected, actual);
```

##### RelativePositionFromBearing

This is a compass bearing where 0 degrees in North or +Y and 90 degrees is East or +X. Increasing bearings move the result clockwise.

```c#
expected.Set(0, 3.3f);
actual = Trig.RelativePositionFromAngle(3.3f, Trig.ToRadians(90));
AreEqual(expected, actual);
```

## Data Structures

### Caching Instances

Even if premature optimisation is evil, the garbage collector can still be your enemy. If you target VR or mobile platforms, garbage collection runs degrade the gaming for your players. Even for PC/Mac/Linux machines, your players may have lower powered machines. Yes, I know, not the serious gamers. However, casual gamers? Even the simple `ForEach` allocates a tiny amount of memory each loop. In some ways, this is the worst. A few areas allocating large chunks then lots of tiny chunks add up to frequent collection runs with much-fragmented memory to investigate. Moreover, let's not even talk about coroutines just now.

What can we do about it without slowing down development or our game? When we are writing code, we can (usually) see where objects are being allocated/discarded a lot. If they can be safely deactivated, cache them for reuse.

Oh, so you want examples? Try these for size.

1. Nodes in tree structures
2. JSON, XML and CSV encoding and decoding
3. Events and emitters
4. Temporary instances used in loops

You get the idea. Feel free to add to the list. Then there is when not to cache.

1. Classes that are only instantiated once or occasionally.
2. Classes you cannot reset for reuse. IEnumerable is one of those, unfortunately, so no caching coroutines.
3. Classes with larger data sets where you instantiate a lot at once, but in very infrequent batches. Judgement is needed. A `Dictionary` or `Map` with 100 entries each with a payload of 100 bytes and an average key length of 5 take about 64k. Not much in the modern scheme of things. In this case cache the payloads, not the `Dictionary`.

Look at `new` carefully. It appears the same for classes and structs, but the latter uses the stack and does not allocate memory.

The `Cache` class is entirely static. It can be used in any class. We call classes that don't know they are being cached as *Cache Agnostic*. You can also use *Cache Aware* classes that are more convenient and readable. For the impatient here are full examples of each.

#### Cache Agnostic Usage

Agnostic usage is quite compact. It is a little harder to read because if the static `Cache<Agnostic>` references.

```c#
// This would normally be in a static constructor. It only need be run once
Cache<Agnostic>.CreateItem     = () =>  new Agnostic {State = "Created"};
Cache<Agnostic>.DeactivateItem = (item) => item.State =  "Deactivated";
Cache<Agnostic>.ReactivateItem = (item) => item.State += " Reactivated";

var agnostic = Cache<Agnostic>.Instance;
using (Cache<Agnostic>.Disposable(agnostic)) {
  Assert.AreEqual("Created", agnostic.State);
}
Assert.AreEqual("Deactivated", agnostic.State);
agnostic = Cache<Agnostic>.Instance;    // will retrieve recycled version
Assert.AreEqual("Deactivated Reactivated", agnostic.State);

var second = new Agnostic();
Cache<Agnostic>.Add(second);        // Add to cache after use
second = Cache<Agnostic>.Instance;    // Retrieve one again
Cache<Agnostic>.Dispose();            // and send it back again
```

#### Cache Aware Usage

Once a class is made cache aware, the resulting code is more explicit. If you want to cache an unsealed class, you can even subclass it and add the functionality below.

```c#
private class Aware : IDisposable {
  private static Aware CreateItem()     => new Aware {State = "Created"};
  private        void             DeactivateItem() => State = "Deactivated";
  private        void             ReactivateItem() => State += " Reactivated";

  private Aware() { }
  public static Aware Instance => Cache<Aware>.Instance;

  public string State { get; private set; }

  public void Dispose() { Cache<Aware>.Dispose(this); }
}
// ...
var aware = Aware.Instance;
using (aware) {
  Assert.AreEqual("Created", aware.State);
}
Assert.AreEqual("Deactivated", aware.State);
agnostic = Aware.Instance;    // will retrieve recycled version
Assert.AreEqual("Deactivated Reactivated", Aware.State);
aware.Dispose();
```

#### Cache Entry Maintenance

If the instance does not hold state, or you choose to deactivate state in your code, then the class can be cached without any further work. Just create it with the `Cache<T>.Instance` command rather than `new`. Like any resource, disposal is important. If the class implements the `IDisposable` interface, then the `using` statement is your best friend. If not, your code needs to use `Cache<T>.Dispose(instance)` or wrap in `using (Cache<T>.Disposable(instance)){}`.   Cached items that are not disposed of constitute a memory leak.

As with the underlying [`LinkedList`](#linked-lists), The [`CreateItem`](#create-a-new-linked-list), [`DeactivatItem`](#create-a-new-linked-list) and [`ReactivateItem`](#create-a-new-linked-list) come in three flavours. The can be added as methods to a class (private or public), attached to a class so that all instances can use them, or attached to an instance. In the latter case, only that specific instance have the methods. Now for the precedence.

1. A class without any actions attached runs the default as listed below, unless;
2. A class defines instance methods with the action name and signature; they are called, unless;
3. An instance action has been set with a static call.

##### CreateItem

1. If no action is set then the class being cached must have an empty constructor.
2. The class has a method `static ClassName CreateItem(){}`
3. Set `Cache<T>.CreateItem` to a function without parameters that returns a new item.

```c#
public sealed class SealedClass {public int index;}
// Choice 1
var sealedClass1 = Cache<SealedClass>.Instance;    // sets index to 0
// Choice 2
public sealed class UnsealedClass {
    public int index;
    UnsealedClass CreateItem() => new UnsealedClass {index = 14};
}
var unsealedClass1 = Cache<UnsealedClass>.Instance;    // sets index to 14
// Choice 3
Cache<SealedClass>.CreateItem = () => new SealedClass {index=23};
var sealedClass2 = Cache<SealedClass>.Instance;    // sets index to 23
```

##### DeactivateItem

Sometimes disposing of an item is not the right thing when it is put back in the recycle bin. Perhaps it contains a server connection that needs to be closed, or a reference to a prefab that has to be stopped.

1. If the payload is an `IDisposable`, call `Dispose()` otherwise do nothing
2. The class has a method `static ClassName DeactivateItem(){doSomething();}`
3. Set `Cache<T>.DeactivateItem = (item) => item.doSomething()`

##### ReactivateItem

You want to reverse the action when the item is reactivated. Reopen the connection, restart the prefab or whatever. The actions are the same as above with R replacing D.

#### Using a Cached Item Safely

A Cache is only as good as it's housekeeping. If a cached item gets forgotten about it won't recycle for later use, and it won't be available for garbage disposal because it remains on an active list. There does not appear to be a safe way using the garbage collector that does not end up making more garbage. Prove me wrong. I would be overjoyed.

If you code can be made sequential (even waiting for Coroutines meets this criterion), the wrapping said code in `using` is the best option.

```c#
var agnostic = Cache<Agnostic>.Instance;
using (Cache<Agnostic>.Disposable(agnostic)) {
  // ... work here ...
}
using (var aware = Aware.Instance) {
  // ... work here ...
}
```

Otherwise, it is your responsibility to call `Dispose` without any opportunity of it being skipped. Remember exceptions.

```c#
Agnostic agnostic;
void StartWork() {agnostic = Cache<Agnostic>.Instance;}
void EndWork() {Cache<Agnostic>.Dispose();}

Aware aware;
void StartWork() {aware = Aware.Instance;}
void EndWork() {aware.Dispose();}
```

If you used a cache item in a body of work, but not outside, you can use `ClearCache()` to send all remaining active items to the recycle bin. It is  what you should do at the end of a scene. This example shows the difference between CleanCache and Clea**r**Cache.

```c#
Cache<Agnostic>.Instance;
Cache<Agnostic>.ClearCache();
Assert.IsNull(Cache<Agnostic>.Entries.First);
Assert.IsNotNull(Cache<Agnostic>.Entries.RecycleBin.First);

Cache<Agnostic>.Instance;
Cache<Agnostic>.CleanCache();
Assert.IsNull(Cache<Agnostic>.Entries.First);
Assert.IsNull(Cache<Agnostic>.Entries.RecycleBin.First);
```

### Disposable.cs - helper for IDisposable.Dispose()

With closures and anonymous functions `using(...){...}` can be implemented where it is needed without creating a new class to manage it. Don't be put off by the `new`. `Disposable` is a struct, so it is not involved directly in garbage collection.

```c#
    [Test]
    public void DisposableExample() {
      using (Ephemeral()) {
        numberOfMonsters += 2;
      }
      Assert.AreEqual(expected: 0, actual: numberOfMonsters);
    }

    private IDisposable Ephemeral() =>
        new Disposable {Action = () => numberOfMonsters = 0};

    private int numberOfMonsters;
  }
```

#### Disposable with Payload

If we want to dispose of an object, we do not have direct access we need to add a payload.

```c#
public static Disposable<TreeContainer> DisposableInstance {
  get {
    var node = trees.Fetch();    // from a cache of objects in a LinkedList

    return new Disposable<TreeContainer> {
      Action = (tree) => {
        tree.Root();    // so all the branches are disposed of correctly
        node.Dispose();    // calls LinkList Dispose
      },
      Payload = node.Item
    };
  }
}
// ...
using (var treeDisposable = TreeContainer.DisposableInstance) {
    var tree = treeDisposable.tree;
    // ... work with tree ...
} // Implicit dispose
```

There are two ways to use `Disposable<T>` that can be combined to make three useful approaches.

1. ***Setting `Action`*** as above. Useful for sealed classes that do not have an `IDisposable` interface but need some cleaning up.
2. ***`IDisposable` Interface*** when the `PayLoad` has one. Calling `Dispose()` on the `Disposable` automatically calls it for the `PayLoad` if it too has the interface.
3. ***Both*** can be used together. Think of a situation where the `PayLoad` implements `IDisposable` but it is part of a parent object that needs to be informed of the change in state.

```c#
  public void DisposableTWithDisposeAndAction() {
    var myClass = new Myclass();

    using (new Disposable<Myclass> {Payload = myClass, Action = Action}) {
      Assert.AreEqual("morning", myClass.howdie);
      myClass.howdie = "hi";
    }
    Assert.AreEqual("hi from me too", myClass.howdie);
  }

  void Action(Myclass myClass) { myClass.howdie += " too"; }
}

class Myclass : IDisposable {
  public string howdie = "morning";
  public void   Dispose() { howdie += " from me"; }
}
```

### Emitter.cs - the observer pattern

*Somebody* owns a ***Emitter*** and many other somebodies can register interest in the said emitter. When anyone who has access to the emitter instance pulls the trigger, all observers are told. There is a second version ***Emitter&lt;T>*** that can pass an object between the emitter and all observers.

```c#
var emitter = new Emitter();

using (var subscription = emitter.Subscribe(new Observer1())) {
  // we now have one subscription
  Assert.AreEqual(expected: 0, actual: counter);
  // Tell observers we have something for them
  emitter.Fire();
  // The observer changes the value
  Assert.AreEqual(expected: 1, actual: counter);
  // A manual call to Dispose will stop the observer listening ...
  subscription.Dispose();
  // ... and calls OnComplete that in this case sets count to zero
  Assert.AreEqual(expected: 0, actual: counter);
  // Now if we fire...
  emitter.Fire(); // not listening any more
  // ... the counter doesn't change because we have no observers
  Assert.AreEqual(expected: 0, actual: counter);
}
// Outside the using - and Dispose was called implicitly but OnComplete was not called again
Assert.AreEqual(expected: 0, actual: counter);
```

```c#
private struct Observer1 : IObserver {
  public void OnNext()      { ++counter; }
  public void OnCompleted() { counter--; }
}
```

While the generic version can pass additional information.

```c#
var emitter = new Emitter<int>();
using (emitter.Subscribe(new Observer3())) {
  emitter.Fire(10);
}
```

```c#
private struct Observer3 : IObserver<int> {
  public void OnCompleted()            { counter--; }
  public void OnError(Exception error) { throw new Exception(); }
  public void OnNext(int        value) { counter = value; }
}
```

While an ***Emitter*** provides some extra facilities to the built-in ***event*** delegates, it does not improve decoupling. It does pave the way for decoupled events using [***CustomAssets***](/CustomAssets), an extension of ***ScriptableObjects***.

### Linked Lists

C#/.Net provides an excellent LinkList implementation. It is, by necessity generic. My implementation has different goals.

1. Reduce garbage collection by keeping remaining nodes in a recycling list.
2. Ordered lists by providing a comparator.
3. Manage state with ***create***, ***deactivate*** and ***reactivate***.
4. All four support functions above can be inherited or injected for class or instance.
5. State management by making it easy to move nodes between lists.
6. Fifo implementation.
7. Walk the list without creating a new or temporary object.
8. Debugging support by logging node movements.

#### Nodes

Each item added to a list is wrapped in a node instance. The node is a class, so it resides on the heap. Because nodes are recycled, no garbage collection is required.

##### Node Name

For clarity, while debugging a node name includes the home and owner lists as well as whatever the held item gives `ToString()`.

##### Node Owner and Home

When a node is created, the list used is set as the `Home` list. When an item is recycled, it is always returned to it's home recycle bin. Each time a node is moved between lists it's `Owner` is set accordingly.

##### Node Comparison

When walking the list, it is sometimes good to see if the node passes or fails a range check. Every node implements <, <=, >, >=, == and !=. The all rely on a single LinkedList function, `Compare` that can be set during initialisation.

##### Move the Node to Another List

Moving nodes provides the core difference between this linked list implementation and others. Moving nodes between lists provide the underlying mechanism for a caching state machine. Used in conjunction with ordered lists to feed them to a state in priority order. `MoveTo` moves the current node to the sorted location or top of the target list, while `MoveToEndOf` moves it to the bottom. The latter is used when disposing of a node so that the recycling list is used oldest first.

##### Update Node Contents

In a statement oriented world we would use `node.Item = value`, but sometimes a more functional approach can be enjoyed `node.MoveTo(state3list).Update(value)`.

##### Dispose of this Node

When you are done with a node, call `Recycle()` or wrap in a `using` compound statement. Each node implements the `IDisposable`  interface. Being a green class, the trash is put into a recycling list rather than left hanging for the garbage collector.

```c#
using (var node = taskList.Top) {
    Process(node.Item);
} // node sent to recycling
```

To set a node adrift call `Destroy` instead. It deactivates the held item and then forgets the node ever existed. As soon as all references in your code go out of scope, the garbage collector is free to reuse the heap space.

```c#
taskList.Top.Destroy();
```

Calling `Destroy` on the LinkedList destroys all entries in both active and recycle bin lists.

##### Fetch a New Node from `Home`

A new (or recycled) node is fetched from the current node's `Home` list then moved to `Owner`. If that is not your requirement, use `node.Home.Fetch()` or `node.Owner.Fetch()`.

##### Push an Item to `Owner`

Given a reference to an entry item, create a node where it's `Home` is the same as the current node. It is pushed onto the `Owner` list for processing.

#### Create a New Linked List

Creation defines how the linked list behaves.

##### Unordered Linked Lists and FIFO Stacks

When an item is added to the list, it always becomes the `Top` element. `Bottom` becomes the oldest entry.

```c#
var numberList = new LinkedList<int>();
Assert.AreEqual(expected: 0, actual: numberList.New());
```

##### Linked Lists with Custom Item Create, Deactivation and Reactivation

It is all well and good to return `default(T)`, being zeros or null references, but then the user of your list neesd to know to create an item if it is not provided. As an example, consider a list of open long-lived HTTP connections.

```c#
var connections = LinkedList<Connection>{
    CreateItem     = () => new Connection(myURL);
    ReactivateItem = (node) => node.Item.CheckForStaleConnections();
    DeactivateItem = (node) => node.Item.SetLowPowerState();
};
// ...
using (var node = connections.Fetch()) {
    response = node.Item.Ask(requestData);
}
```

Yes, I know. This example is ignoring the asynchronous nature of the request and the possibility that the connection has timed out. All in good time.

`DeactivateItem` will not call `Dispose()` on the item if it is an `IDisposable`. Override it if you need that functionality. If the item needs reactivation when retrieved for reuse, set an activation parameter as demonstrated above.

`DeactivateItem(node)` is called before the node is placed in the recycle bin.

All three custom functions can be created in different ways, depending on need.

```c#
// 1. per-class/struct/value-type
LinkedList<int>.CreateItemStatic     = () => -1;
LinkedList<int>.DeactivateItemStatic = (node) => node.Item = -2;
LinkedList<int>.ReactivateItemStatic = (node) => node.Item = -1;
LinkedList<int>.CompareItemStatic = (a, b) => a.CompareTo(b);
// 2. inherited
private class MyClass {
    private static MyClass CreateItem() => new MyClass {State = "C"};
    private void DeactivateItem() => State = "D";
    private void ReactivateItem() => State = "R";
    int CompareItem(MyClass a, MyClass b) => a.State.CompareTo(b.State);
    public int State;
}
// 3. per-instance control
var numbers = LinkedList<int> {
    CreateItem     = () => -1;
    DeactivateItem = (node) => node.Item = -2;
    ReactivateItem = (node) => node.Item = -1;
    CompareItem    = (left, right) => left.CompareTo(right);
}
```

The static methods will be active for any items of that class unless a per-instance invocation overrides them.

Inherited methods are be active for any items of that class unless a per-instance or static invocation override them.

Per-instance invocations only effect one instance of a linked list.

##### Ordered Linked Lists

Caching state machines and the like need a list of jobs to process in priority order. Priority could also be a time, a distance or any other measure that we can compare.

```c#
var fences = new LinkedLisk<Geofence> {
    CompareItem = (left, right) 
        => node.Item.Distance.CompareTo(cursor.Item.Distance)
}
// fences nodes now implement <, <=, >, >=, == and !=
if (fence.Active) fence.MoveTo(fences);    // injects in sorted order
```

When an item is created or moved to an ordered list, it is placed on sorted order rather than just at the top.

As above, `CompareItem` can be inherited, set for a class or an instance.

#### List Disposal

Linked lists are commonly used as statics to keep lists of reusable elements. Sometimes they have a limited life, so need to be cleared for disposal or recycling in a parent linked list. There are two levels of cleanliness.

1. `Discard()` disposes of any active elements, placing them in the recycle bin for later use. Use when you want to keep the linked list, but remove any outstanding elements. It is implicitly called if it is an Item in a parent LinkedList.
2. `Dispose()` removes items from the recycle bin as well so that the linked list can be safe for the garbage collector to pick up.

#### Node Creation and Movement

##### Add an Item to the Current List

If you have an item that has not been on a list, use `Add` to correct that oversight.

```c#
var node = fences.Add(newFence);
```

It will return a reference to a node holding the new item.

##### Recycle a Currently Unused Node

If you require a node where the contents are initialised elsewhere, use `Fetch`. It picks one from the recycling heap. If the recycling is empty, it creates a new item and matching node for you. If `CreateItem` has not been set the item is `default<T>`.

```c#
using (node = weatherEvents.Fetch()) {
    node.Item.UseMe();
}
```

##### Move Item Between Lists

So now we get to the part where the real magic happens. Different components can own lists of Jobs. When they have done there but they can toss the job (node) to the next component that needs it.

```c#
void Update() {
    if (! jobs.Empty) {
        var result = jobs.First.Item;
        if (result == null) {
            jobs.First.Discard(); // could have used jobs.Pop()
        } else {
            jobs.First.MoveTo(dispatcherList);
        }
    }
}
```

In this admittedly theoretical example, once a job has been processed it is either finished or put on another job list for a dispatcher to decide what is next. Note that this example only works with small numbers of jobs, since it is only processing between 30 and 60 jobs a second. You could use `Walk`, but personally, I would use something other than Update - possibly an Emitter so we can process only when needed.

There is also a function to move to the end of a list. It is used with the recycle bin to better disperse usage (LRU - least recently used). It can also be used to move an item to the end of the list regardless of priority.

```c#
var result = jobs.First.Item;
if (result == null) {
    jobs.First.Discard(); // could have used Pop()
} else if (jobs.IHateThisPerson) {
    jobs.First.MoveToEnd(jobs);    // will never get processed
}
```

##### Disposal of a Node

Disposing of a node once it has served its purpose calls `Dispose()` on the item if it is an `IDiposable`. It then moves the node to the recycle bin for where it was originally created.

If an item has a known lifetime then by far the best way is with a `using` statement. Like `Try/Finally` it is guaranteed to be called. If the work requires waiting for resources, then put the `using` statement in a Coroutine, or it's equivalent.

```c#
IEnumerator MyCoroutine() {
    using (var node = jobList.Fetch()) {
        while (!node.Item.Ready) yield return null;
        Process(node.Item);
    }
} // node will be placed back in recycling after Dispose()
```

Sometimes we do not know the lifetime of an item beforehand. In this case, whoever does needs to call `Dispose()` manually.

#### A Lifo Stack

For the uninitiated, ***Lifo*** is an acronym for *Last in first out*. A linked list is well suited for Lifo stacks. The return stack used by most languages with functions is Lifo, so every return returns from the most recently entered function. Stack-based languages such as FORTH and FICL make working with Lifo an art form of efficiency (and unreadability). We use Lifo stacks every day with the undo stack when editing or the back button on a browser.

##### First

`Top` is the standard entry to the linked list, so using Top has no overhead. `Top` is null if the list is empty. `Top` allows access to the first item for processing before deciding what to move or discard it. Don't expect `Top` to remain when you yield or otherwise relinquish the CPU. If you need it longer, move the item to a list to which your code has exclusive access.

```c#
var working = new LinkedList<MyWorld>();
// ...
var node = readyList.First?.MoveTo(working);
if (node != null) {
    yield return WaitForWorld(node);
    node.Dispose();
}
```

`Top?.MoveTo` ensures that the readyList only provides a node if it is not empty.

##### Second

`Second` is the second entry below `First`. It is null if the list has one entry or is empty. Use it as a premonition of things to come. For ordered list you can tell if there is more immediate work. Can you think of any other uses?

##### Last

`Last` is the other less visited end of the stack/linked list. It is used a lot internally, but I can't think where I would use it elsewhere. Great for anyone who likes burning the candle from both ends. There is a `MoveToEnd` method that makes a node the new Bottom.

##### Empty

The example above for `Top` is not how I would do it. A better method would be

```c#
var working = new LinkedList<MyWorld>();
// ...
if (! readyList.Empty) {
    using (var node = readyList.Top.MoveTo(working)) {
        yield return WaitForWorld(node);
    }
}
```

For this example, both methods are identical because `yield` does not pass back exceptions, so `using` has no benefit over a manual `dispose`.

##### Count

`Count` walks a linked list to see how many nodes there are.

##### Push

`Push` is another way of moving a node. You can push an item or a node onto a stack.

```c#
var node = idleList.Pop();
dispatchList.Push(node);
// ...
var myItem = new MyItem();
dispatchList.Push(myItem);
```

##### Pop

Also, of course, for every push, there has to be a pop. However, what do we do about node conservation? Easy, put it in the recycle bin. Remember to finish with it or move it somewhere safe before the next implicit or explicit yield. You don't need to dispose of the node since it is already indisposed.

```c#
using (var node = taskList.Top) {
    Process(node.Item);
} // node sent to recycling
// ... is the same as
node = taskList.Pop();
Process(node.Item);
```

In some ways, this is better because you are free to move the node without it being moved back to the recycle bin for you.

#### Node Walking

Sing to the melody of *Jive Walking*. Seriously, node walking is the best way of processing all or some of the items in a list. 

```c#
var tasks = new LinkedList<Task> {
    CompareNodes = (left, right) => left.Item.Ready <= right.Item.Ready
}
// ...
tasks.Add(new Task {Ready=Time.RealtimeSinceStartup + 60});    // 1 minute
// ...
void Update() {
    for (var node = tasks.First; node != null; node = node.Next) {
        Check(node.Item);
    }
}
```

 Think of a list of tasks where only tasks that have exceeded their use-by date are to be processed. Because we want to discard the node when done, we need to keep a reference to Next.

```c#
void Update() {
      var next = node.Next;
      for (node = list1.First; node != null; node = next, next = node.Next) {
        if (node.Item.Ready >= Time.RealtimeSinceStartup) break;
        using (node) { Process(node.Item); } // node is discarded afterwards                 }
}
```

By wrapping it in a `using` statement `Dispose` is called even if an exception was thrown.

#### Debug Mode

Because linked lists can be used in a cached state machine, knowing where a task is going can be an essential part of understanding the functionality.

##### Name

Refers to the name of the list as provided in the constructor. It defaults to the name of the item type followed by an ordinal number.

##### DebugMode

When enabled, `DebugMode` causes a log entry for every creation or movement of a node. Because this includes stack dumps, you can find out who did what where.

##### Dump

`Dump` returns the current contents of a linked list as a multi-line formatted string.

##### ToString

Returns a string containing the list name and counts for it and the attached recycle bin.

### Map - A Dictionary Wrapper for Conceptual Change

Underneath, a `Map` is still a C# `Dictionary` with similar object references for keys and values. This allows for mixed types that can be converted on retrieval.

My limited tests show that the `Dictionary` is faster than `SortedList`. The latter uses `Array.BinarySearch` to find entries. I have read other performance tests that report binary searches to be faster for small numbers of keys. I checked this on my MacBook Pro - and the Dictionary approach was twice as fast with 10 keys and hundreds of times faster will 1000 or more keys. That is not to say that the results would be the same on other hardware - an Android phone for example.

For `Map`, the `Hashtable` class would have made the perfect base, but in more tests `Dictionary` was consistently faster. Interestingly, on the tests I created, `Map` can be up to a third again faster than `Dictionary`.

#### Creating a New Map

It is possible to seed a new `Map` by passing in key-value pairs. The keys do not have to be strings. If either strings or values are primitives they will be auto-boxed.

```c#
var map1 = new Map();
var map2 = new Map("One", 1, "Two", "Twice", "Three", "Thrice");
var map3 = new Map(keyValuePairArray);
```

#### Add: Adding Entries

You can add as many entries as you like by passing in key-value pairs. `Add` returns a reference to the `Map` for chaining.

```c#
var map  = new Map("One", 1, "Two", 2, "Three", 3);
var more = new object[] {"Six", 6, "Seven", 7};
map.Add("Four", 4, "Five", 5).Add(more);
```

#### Set: Creating or Updating a Set

A `Set` is a convenience method to fill a `Map` with keys referencing null values.

```c#
var set = new Map().Set(1, 3, 5, 7, 9);
set.Set(11, 13, 15);
```

#### Remove: For the Truly Destructive

`Remove` causes `Map` to completely forget one or more entries.

```c#
var map = new Map("One", 1, "Two", 2, "Three", 3);
map.Remove("Two", "One");
Assert.AreEqual(1, map.Count);
```

#### Retrieve a Key/Value Pair

The core method for search and rescue is an array override. It attempts to retrieve the value for the supplied key and sets some class instance values. It then returns a reference to `Map` for chaining.

```c#
var map = new Map("One", 1, "Four", 4, "Three", 3, "Five", 5, "Two", 2);
Assert.IsTrue(map["Three"].Found);
Assert.IsFalse(map["Seven"].Found);
```

##### Found

We always need to know if a search was successful. We can't rely on `Value` being `null` since that may be a valid result.

```c#
var set = new Map().Set(1, 3, "Five", 7, 9);
if (set[7].Found || set["Seven"].Found) Debug.Log("We have sevens");
```

##### Key

For completeness, `Map` saves the last key searched - whether it is successful or not. It means you can pass the map around without having to search for an entry again.

```c#
var map = new Map("One", 111, "Two", "2", "Three", new Map());

if (map["Three"].Found) Debug.Log($"Found '{map.Key}'");
```

##### Value

Value is either null if the last retrieval failed or it is an `object`.

```c#
var map = new Map("One", 111, "Two", "2", "Three", new Map());
Assert.AreEqual(expected: "2", actual: map["Two"].Value);
Assert.IsNull(map["TryMe"].Value);
```

##### Return a  Value of a Specific Type

If you know what you have as a type for a value you can retrieve it with the generic `As<T>`. If you are wrong, it returns default(T), which is null for objects, 0 for numbers and empty structs.

```c#
var map = new Map("One", 111, "Two", "2", "Three", new Map());
Assert.AreEqual(expected: "2", actual: map["Two"].As<string>());
Assert.AreEqual(expected: 0,   actual: map["Two"].As<int>());
```

##### IsA: Check Map for Key of a Specific Type

If you need confirmation on whether the value is of a specific type, use `IsA`.

```c#
var map = new Map("One", 1, "Two", "2", "Three", new Map());
Assert.IsTrue(map["Two"].IsA<string>());
Assert.IsTrue(map["Three"].IsA<Map>());
Assert.IsFalse(map["Two"].IsA<int>());
```

##### TypeOf: For Code that Doesn't Have a Clue

If the map comes from an external source and the values could be anything, then you have two choices. You can use `ToString` to get a (hopefully) readable representation, or you can use `TypeOf`. It is considered bad form to have to stoop to this approach, but if you have unknown data, what else can you do? It is not as bad as it looks. If the data is parsed from JSON, for example, it can only be a string, a number, a boolean or `null`.

```c#
Map types = new Map(typeof(long), 'l', typeof(string), 's', typeof(double), 'd');

switch ((types[jsonNode[0].TypeOf].As<char>())) {
  case 'l': return Process(jsonNode[0].As<long>())
  case 'd': return Process(jsonNode[0].As<double>())
  case 's': return Process(jsonNode[0].As<string>())
  default:  return Process(null);
}
```

#### Keys: Iterating Through a Map

The iteration techniques here are designed to use as little of the heap as possible to minimise garbage collection. Both mobile and VR apps suffer if the garbage collector is kept busy.

There is one other crucial distinguishing feature. By default, the keys are returned in the same order as they were added. This is valuable if they are coming from structured data such as XML or JSON.

##### Count: of Items in a Map

`Count` can always tell you how many items are in the `Map`. It can be used to check if the map is empty or in an expected size range. It is also used for object key iteration below.

##### When all Keys are Strings

Because `string` keys are the most common, they get special treatment.

```c#
for (var key = map.First; key != null; key = map.Next) {
  Process(key, map.As<string>);
}
```

##### For Object Keys

Object keys are even more fundamental. As well as `Count`, `Map` allows access to keys with an integer array index.

```c#
for (int i = 0; i < map.Count; i++) {
  Process(key, map[i].Value);
}
```

##### Sorting

As mentioned above, without intervention the order of the keys for either iteration method is the order that they were inserted into the map in the first place. This is useful for data where the order matters, such as JSON and XML.

When we need a different order, use one of the `Sort` functions. Without parameters, `Sort` uses the default sorting for an object. This is alphabetical for strings and numeric ascending for numbers. If you mix your keys, it becomes a dog's breakfast.

```c#
var    map    = new Map("One", 1, "Four", 4, "Three", 3, "Five", 5, "Two", 2);
string actual = "";
for (var key = map.Sort().First; key != null; key = map.Next) actual += key;
Assert.AreEqual("FiveFourOneThreeTwo", actual);
```

For more interesting cases, `Sort` can be provided with a comparison lambda.

```c#
var    map    = new Map("One", 1, "Four", 4, "Three", 3, "Five", 5, "Two", 2);
string actual = "";
map.Sort((x, y) => map[x].As<int>().CompareTo(map[y].As<int>()));
for (var key = map.First; key != null; key = map.Next) actual += key;
Assert.AreEqual("OneTwoThreeFourFive", actual);
```

In this example, we are sorting the keys by the value, not the key.

### Pick.cs - Interface to choose from options

Interface to pick an item, probably from a list, probably random. It all depends on how you implement `Pick()`.

```c#
class PickImplementation : Pick<string> {
  private int    count;
  public  string Pick() => (++count).ToString();
}
// ...
PickImplementation nose = new PickImplementation();
Assert.AreEqual("1", nose.Pick());
Assert.AreEqual("2", nose.Pick());
Assert.AreEqual("3", nose.Pick());
```

### Selector.cs - maintain and pick from a list

1. Select a random image or sounds or actions from a list.
2. Choose the next item from an ordered list of training steps.

```c#
Selector<int> selector = new Selector<int> {
    Choices = new int[] { 0, 1, 2, 3, 4 };
}

for (int idx = 0; idx < 100; idx++) {
  int at = selector.Pick();
  Use(at);
}
```

#### Selector Initialiser

The magic is in having different pickers for different requirements. The constructor allows for three types. Add more by overriding `Pick()`.

```c#
new Selector<T> {
    Choices             = listOfT,    // default is null
    IsRandom            = true,       // default is true
    int exhaustiveBelow = 30        // default is 0
}
```

- ***Sequential***: `isRandom` is false or;
- ***Random***: `exhaustiveBelow` is less than the number of choices.
- ***Exhaustive Random***: `exhaustiveBelow` is greater than the number of choices.

To return in a random order, set ***Exhaustive Random***. Nothing repeats until the list is exhausted. Each cycle is in random order.

#### Exhaustive Random Selections

If there are a small number of choices, the player recognises the repeats, and they won't appear random. If the same item repeats immediately it becomes particularly apparent. The solution is to use exhaustive random selection. No item is returned twice until all items have had a turn at being displayed.

Exhaustive Random is not necessary for large sets of values. Set a watermark by giving `exhaustiveBelow` a value. If the number of choices available is below this value, exhaustive random selection occurs. If it is above, pseudo-random selection occurs.

#### Selector Choices

If the list of items to choose from changes, update the selector with `Choices`. The same picker is reset and used.

```c#
Selector<int> selector = new Selector<int> {Choices = { 0, 1, 2, 3, 4 }}
selector.Choices = new int[] { 5, 6, 7, 8 };
```

#### Selector CycleIndex

`CycleIndex` return the index in the `Choices` array of the last item returned. If we were using `Selector` to return the next training item, then we may well need the index to report progress or to go back and repeat a section.

### Simple Stacks

C# provides a quite serviceable `Stack` class. Even `LinkedList` from this package can provide a powerful stack. I think both are too heavy when we want a simple stack. This implementation is complete in under two dozen lines of code. It has some unique features that make it most suitable for lightweight applications.

1. It is instantiated with `Stack<T>.Instance`.
2. It is an `IDisposable`. Call `Dispose()` when you are done, and the instance is cached for later - reducing garbage collection.
3. It is easy to access and change the most recent item pushed with `Top`, making it perfect for dynamic data that needs a history.
4. `Push` and `Pop` both return the current item. It makes data with history easier to create.
5. The constructor is protected so inherited classes can bypass the caching. Useful if they cache everything themselves.

The easiest way to show off the functionality is with the source to `CounterStack`, a class that inherits from `Stack<int>`.

#### CounterStack

```c#
public class CounterStack : Stack<int> {
  public new static CounterStack Instance => Cache<CounterStack>.Instance;
  public int Start(int startingValue = 0) => Math.Abs(Push(startingValue));
  public int Next() => Math.Abs(++Top);
  public bool Reached(int bounds) {
    var reached = (Top >= bounds);
    if (reached) Pop();
    return reached;
  }
  public override void Dispose() { Cache<CounterStack>.Dispose(this); }
}
```

So, thanks to `Stack`, `CounterStack` is concise. However, what does it do? Well, the name says it all - it is a stack of counters. OK, you say, but why? There are probably other uses, but I use it for an alternate form of iteration. We know that `foreach` causes lots of garbage to collect due to the state machine being generated by the compiler when a method returns `IEnumerator`. The problem is that these functions do not reset, so a new one has to be created for each turn of the loop. By providing methods `First` and `Next` in a class we can implement easy-to-use iteration with minimal garbage.

```c#
for (var key = map.First; key != null; key = map.Next) {
  Process(key, map[key]);
}
```

Cool, huh? However, how does it work? Here is the implementation in ***Map.cs***.

```c#
public object First => (Count > 0) ? keys[index.Start()] : null;
public object Next => index.Reached(Count - 1) ? null : keys[index.Next()];
private CounterStack index = CounterStack.Instance;
```

We could have just used `int index;`. In this case, that would probably OK, but in many similar instances, we have problems when one iteration occurs in another. Besides, this is easier to read.

### Trees

A tree Container for Varied Structured Data.

#### Creating a Tree Container

For no particularly good reason a new tree is created with a static property. `Trees` is type agnostic, so no additional information is required. The tree contains state including the current branch, array or leaf node. It starts by pointing at the root node.

```c#
var tree = Trees.Instance;
Assert.IsTrue(tree.IsRoot);
```

#### Tree Navigation

The tree root is the known starting point. You can return to it explicitly with `tree.Root()` or implicitly with `To`. Moving back to root from the current node is implemented with `Parent(path)` or with ***..*** in the path.

```c#
var tree = Trees.Instance.To("A.B.C");
tree.To("A.B");
Assert.IsTrue(tree.Has("C"));
Assert.IsTrue(tree.Parent().Parent().Parent().IsRoot);
tree.To("A.B.C...B");    // A->B->C<-B<-A
Assert.IsTrue(tree.Has("C"));
```

##### Tree Walking

All the tree walking methods can be given a path to travel up or down the tree. The question is, which way is up? If we are using a tree from nature, the root is down, and we go up to branches and leaves. Then again we represent tree structures on the page and screen with the root on the left with branches and leaves to the right.

Most provide a path to follow. It can be a single string with a `.`  separating nodes or a list of objects for non-string keys. You can walk back towards the root with `..` with each additional dot being another step back.

```c#
var tree = Trees.Instance.Add("A.B.C1..C2..C3").To("A.B");
Assert.AreEqual("C1,C2,C3", Csv.ToString(tree.Children));
```

All these methods, bar `Anchor` return a reference to `Tree` for chaining.

###### Root()

A tree instance keeps its location as an internal state, but often we have a path from the root. `Root()` is functionally identical to `To()` without parameters.

###### To(params object[] path)

`To` searches from the root along the specified path. It returns null if a node does not exist. In this case, `Failure` is set and the tree references the last found node on the path.

```c#
var type = tree.To("Authors.Books.Type")?.Leaf;
Assert .IsFalse(tree.Failure)
```

###### Next(params object[] path)

Next is identical to To except that it starts from the current location in the tree without going back to the root.

```c#
tree.To("Authors")
var type = tree.Next("Books.Type")?.Leaf;
Assert .IsFalse(tree.Failure)
```

##### Children

When investigating a tree where you do not have full disclosure of the structure or when serialising the contents, we need access to all values. `Children` returns an array of objects that represent the keys for this node in the tree. This is particularly useful for array nodes where the children are keyed on the index.

```c#
var tree = Trees.Instance.Add("A.B.C1..C2..C3").To("A.B");
Assert.AreEqual("C1,C2,C3", Csv.ToString(tree.Children));
```

Better yet, use `FirstChild`/`NextChild` for more concise code (See [Anchor](anchor) below)

###### Anchor

Get back to where you once belong. Mark a spot on the tree to return to after a processing jaunt.

```c#
    for(var key = tree.To("Authors").FirstChild; key != null; key = tree.NextChild) {
      using (tree.Anchor) {Process(authors[i]);}
    }
```

#### Tree Contents

Every node can store a leaf as an object. Access and updates are implemented for the current node or a child of a node.

```c#
var tree = Trees.Instance.Add("A.B.C");
// Update the current node leaf value
tree.Leaf = "Leaf Update";
// Update a child node leaf value
tree.To("A.B")["C"] = "Array Update";
```

##### Arrays

Children can also be accessed by array nomenclature. Unlike tree walking, the current node does not change. The value of a named (or numbered) child node is returned.

```c#
var tree = Trees.Instance.Add("A.B.C");
tree.To("A.B");
tree["C"] = "Array Update";
Assert.AreEqual(tree["C"], tree.To("A.B.C").Leaf);
// And integer access
tree.To("A.B");
tree[1] = "Array Update";
Assert.AreEqual(tree[1], tree.To("A.B.C").Leaf);
```

There are some convenience methods for some common conversions.

- ***`IsNumber`*** returns true of the string is a valid integer or floating point. `Failed` is also set for post-conversion checking.
- ***`Long`*** returns a long number for both a whole number string and a floating point representation. It sets `Failed` if the leaf value was not a number.
- ***`Double`*** returns a double for both a whole number string and a floating point representation. It sets `Failed` if the leaf value was not a number.
- ***`Boolean`*** returns true if the word starts with ***t*** for true.
- ***`IsNull`*** returns true if the leaf is null or if it is the text string `null`.

#### Tree Additions and Removals

While `To` or `Next` baulk if it can't find a node on the path, `Add` just creates all of them as needed. Filling a leaf with data is a separate operation. The path for `Add` is relative.

```c#
Trees.To("A.B.C").Add("Quote.English.Comtemporary").Leaf = "Now is the time";
```

###### Dispose()

`Dispose` removes the current node and every node towards the leaves.

```c#
tree.To("A.B").Dispose();
```

#### Tree Export Support

Sooner or later you need to serialise or deserialise from or to a tree. For that purpose `Key` returns a string that represents the path from the root to the current location. From there you can iterate through one level of child branches with `FirstChild` and `NextChild`.

```c#
void SerialiseTree(tree) {
    Debug.Log(tree.Key);
    for (var name = tree.FirstChild; name !=null; name = tree.NextChild) {
        Debug.Log($"{name} = {tree[name]}");
    }
}
```

If you need to know how many branches to prepare storage, use `Children`, which is an array of the same objects returned above. So, `Children.Length` is the number of child branches.

## Text Manipulation

### Csv.cs - serialization of comma-separated lists

##### Static Line Serialisation

`ToString(params <T> list)` takes a list of parameters or a single array and uses `ToString` on each then joins them with commas.

```c#
      expected = "1,3,5,7,9";
      actual   = Csv.ToString(new[] {1, 3, 5, 7, 9});
      Assert.AreEqual(expected, actual);

      expected = "One,Two,Three,Four,Five";
      actual   = Csv.ToString("One", "Two", "Three", "Four", "Five");
      Assert.AreEqual(expected, actual);
```

### Json.cs - parse any JSON to dictionary

And it came about that the computer was born and all was good. Then there was another computer and the need to share things. It was easy. Knowing both sides, we can send data the computer understands. But wait, now some computers see the binary world differently. OK, let's make it human readable. Computers are faster at deserialisation by then. Comma separated variable (CSV) files became popular, but they lacked depth. Enter SGML and then XML. Fifty years have passed. There are signs at the airport saying "We are an XML Company!". What does that mean? It's just a way for all machines (and some people) to be able to read the same data. XML uses a DTD (document type definition). If an XML document does not pass the DTD rules, then it is no good. Toss it out. Great for developers. If it passes the rules, then it is easy to deserialise directly into a computer readable (i.e. binary format) object. Mind you, by hiding the structure from the developers they were free to build as they liked. I have seen Windows applications where to change the state in a drop-down will cause millions of bytes to pass between client and server. And everyone was happy. Then JavaScript became more standardised and faster, and the Web App was born. Parsing XML in JavaScript was slow and difficult - even without checking it against a DTD. Unlike traditional server languages, JavaScript has dynamic data structures. You can send any structured data down the line and only work out what it contains when you need to. Some bright spark decided to send JavaScript source full of data structures. Javascript is fast at compiling itself. This method is now called JSONP. But, sending code has its risks even in a sandbox. Besides we can make the JavaScript compiler even faster if we give it a more rigid format and a subset of JavaScript. JSON was born. And all was good. Then the people who don't live flexibility said "We can't have that" and started insisting on rigid structures in JavaScript. So, now we have something like XML but without the DTD to help us get it right at both ends. Developers are now spending more time than with XML.

We must stand up and fight. JSON for JSON. Allow me to get the data I need, not just what the suites have defined.

#### Parse

After the above rant it would be wrong to create a restrictive JSON reader. In the vein `Parse` does not throw any explicit errors. In attempts to create an in-memory tree structure with both keys and values as strings. Keys and values can be wrapped in quotes or not. If they are the comma between entries is optional. Arrays are just branches with keys that are integers. A search can use a string or integer key.

Once you have parsed the JSON, use the [Trees](#trees) interface to process the data using the `tree.Node` member.

```c#
// reasonably accurate JSON
json.Parse(@"{""Not my age"":23}");
Assert.AreEqual("23", json.Node["Not my age"]);
// no starting braces
json.Parse(@"""Not my age"":24");
Assert.AreEqual("24", json.Node["Not my age"]);
// no colon either
json.Parse(@"""Not my age"" 25");
Assert.AreEqual("25", json.Node["Not my age"]);
// no quotes around key
json.Parse(@"Not my age: 26");
Assert.AreEqual("26", json.Node["Not my age"]);
```

## Unity Support

### Components

`Components` is a static helper class with functions to create and find Components. They are all wrappers to ***slow*** Unity procedures, so cache the results. I created these primarily for testing since any test harness should not be coupled to the application. Since then I have found them useful to get inside prefabs from other sources. Still not a good idea in production, but sometimes better than breaking existing code.

#### Components.Find&lt;T>(path...)

Search the current scene for components of type `T`, then return the one with sparse game object path supplied. The path is absolute for the scene, but not all components need to be entered. Just enough to make the path unique. The double-slash is optional, but I find it handy to remind me of where the unmentioned part of the path is.

```c#
// No path, returns null (not found)
var text = Components.Find<Text>();
Assert.IsNull(text);
// Sparse GameObject path leading to component of specified type
text = Components.Find<Text>("Canvas", "Level");
Assert.IsNotNull(text);
Assert.AreEqual("Button Two", text.text);
// path can also be a single string. // is convenience to show sparse path
text = Components.Find<Text>("Canvas/Level//Text");
Assert.IsNotNull(text);
// Returns first if path is not unique enough
text = Components.Find<Text>("Canvas//Text");
Assert.AreEqual("Button One", text.text);
// We don't even need to specify the root
text = Components.Find<Text>("Level");
Assert.AreEqual("Button Two", text.text);
```

#### Components.Find&lt;T>(inGameObject, path...)

Find a component by type within a specified GameObject. As above, the path can be a list of sparse segments or a single string with a slash-separated path.

```c#
// if we know the parent object we can start from there.
var canvas = GameObject.Find("Canvas");
var text   = Components.Find<Text>(canvas, "Text");
Assert.AreEqual("Button One", text.text);
```

#### Components.Create&lt;T>(path...)

Follow the fully qualified path, creating game objects that don't exist on the way. Add an instance of component `T` to the final game object.

```c#
// create a root GameObject with the specified name and add component
var text = Components.Create<Text>("Canvas/New Path/Created");
text.text = "Created Text Component";
Assert.AreEqual("Created Text Component", Components.Find<Text>("Created").text);
```

#### Components.Establish&lt;T>(path...)

Find a component if it exists or creates it if it doesn't. Because of the `Create`, the path must be full, not sparse.

### ConditionalHideAttribute

This tool comes straight from [http://www.brechtos.com](Brecht Lecluyse) in a [http://www.brechtos.com/hiding-or-disabling-inspector-properties-using-propertydrawers-within-unity-5/](a blog from November 2015).

Any reasonably complex `MonoBehaviour` can have quite a few items to display in the inspector. Often some items are only valid if another inspector-visible attribute is in a specific state.

1. Booleans are true to display conditional fields
2. A string is not empty and not just spaces
3. A reference object has been set (game object, prefab, and more)

```c#
[SerializeField]private bool enableAll = true; // number and userName visible on true
[ConditionalHide("enableAll"), SerializeField] int number;
[ConditionalHide("enableAll"), SerializeField] string userName;

[SerializeField] string aString; // hiThere only visible if string non-empty
[ConditionalHide("aString"), SerializeField] int hiThere = 77;

[SerializeField] private GameObject text;  // whatNow only displays if object set
[ConditionalHide("text"), SerializeField] int whatNow = 33;
```

#### Before

![ConditionalHide-disabled](ConditionalHide-disabled.png)

#### After

![ConditionalHide-disabled](ConditionalHide-enabled.png)

### Label Attribute

One of the challenges of using generic scriptable objects is the often uninformative labels in the inspector. In this truncated example below, we have a generic class with a variable that can only be set in the inspector. `Stringer` inherits from it, but by using an attribute decorator `Labels`, I can rename the field to something more meaningful.

In the generic class where you have ***Inspector*** fields you want to rename, give them a `[Label]` attribute. In the concrete classes, use the `Labels(before, after, ...)` class attribute decorator with entries that match the before and after label value.

```c#
  public class OfType<T> : WithEmitter { [SerializeField, Label] private T value; }
// ...
[Labels("Value", "Text")] public sealed class Stringer : OfType<string> {}
// or if there is only one,a s here, the label to replace can be implied
[Labels("Text")] public sealed class Stringer : OfType<string> {}
```

In this example, we see a ***Text*** label instead of the generic `Value` one.

### Log - Plug-and-play Logging

The Askowl `Log` class provides an easy-to-use interface to the Unity debug log that can also be used with analytics reporting. If Unity Analytics is enabled, log messages are sent there as well as to the console. Without adding any more consumers, log messages can be sent to the `Debug.Log` console and `Unity.Analytics`.

Console messages are only displayed when in the Unity editor. For other builds, you need to set `Log.ConsoleEnabled = true` explicitly.

Unity Analytics are set up as per these [Unity instructions](https://docs.unity3d.com/Manual/UnityAnalyticsSetup.html). They can then be explicitly disabled with 'UnityEngine.Analytics.Analytics.enabled' or if the target platform does not support it.

Any third party analytics or logging library can easily be incorporated as documented below.

#### Basic Logging

Create a static delegate for each script or class that can write to the log.

```c#
private static Log.MessageRecorder log = Log.Messages();
```

You now have a function to call with a signature of:

```c#
void MessageRecorder(string action, string message, params object[] more);
```

Think of the action as what your code was doing when you needed to record a message. It is a way of grouping messages in the analytics systems. Don't group by class or file-name as the component and delegate names are already recorded.

```c#
log(action: "Level Completed", message: "Success", "Level=", 1, "Time=", 30.3);
```

Or you may choose to have a different action for each level so that you can compare player performance. The output to the console takes the form:

> ***Level Completed***: for 'GameStats' -- result=Success, Level=1,Time=30.3,line=14,member=log

#### Log Parameter Formatting

Log information is supplied to the consumer as:

1. **Action or status** - supplied in call or when building an event
2. **Component** - filename of calling method/field
3. **Result** - being the message supplied in the call
4. **Member** - being the name of the field or function used to create the logging delegate.
5. **More** - variable list of parameters from the logging call

The *member name* is interesting. If you generate the delegate as a static field as recommended above, it is the name of that field. You can use this field to further differentiate messages by creating multiple fields.

```c#
private static Log.EventRecorder   todo   = Log.Events(action: "Todo");
private static Log.EventRecorder   fixBug = Log.Events(action: "Todo");
```

A log call can include any number of additional parameters. They can be either single objects or key-value pairs. If a parameter is a string that ends in an equals (=), it becomes a key, and the next parameter becomes a value. Log consumers can generate a dictionary using these rules with `Log.ToDictionary`. Objects that are not involved in key-value pairs become dictionary entries where the object is the key, and the value is null.

#### Event Logging

In many situations, you want a limited set of consistent actions with varying messages. For messaging purposes, the action can be called the event, and the delegate call only has to supply a message.

```c#
private static Log.EventRecorder   healthUpEvent   = Log.Events(action: "Health");
private static Log.EventRecorder   healthDownEvent = Log.Events(action: "Health");
private static Log.EventRecorder   error           = Log.Errors();
```

The example includes two separate ***Health*** events that are differentiated by the member field in the result. This level of granularity is rarely needed, but it is nice to know for when you do. ***Error*** events are unique in that the action is always "Error".

#### Warnings

Warnings are identical to messages except they call a different method in the consumers. In the Unity console, you can see them with a yellow marker. Most analytics interfaces treat them the same as messages.

```c#
private static Log.MessageRecorder warning = Log.Warnings("Warning");
private static Log.EventRecorder   todo    = Log.Events(action: "Todo");
```

#### Console Log Formatting

If there is only one optional parameter and it is a `Unity.Object` then it is passed to     `Debug.Log` as the second parameter to provide extra detail.

#### Actions

Individual messages can be highlighted in the log by colour, bolding or italics. An RTF string can be created with the `Log.Action` method.

```c#
public static string Action(string text, string colour, bool bold, bool italics);
```

You can even save these in a map called `Actions` to be used whenever an action is used. They keys should be all lower case as this is applied to actions before comparison.

```c#
Log.Actions.Add("deleteme", Log.Action("Delete Me", RichText.Colour.Aqua,
                                       bold: true, italics: true));
// ...
log(action: "DeleteMe", message: "later");
```

The `Actions` map comes pre-loaded with ***TO-BE-DONE*** and ***FIX-ME*** templates.

```c#
// All become "TO_BE_DONE" in red in the log
private static Log.EventRecorder todo       = Log.Warnings(action: "Todo");
private static Log.EventRecorder tbd        = Log.Warnings(action: "TBD");
private static Log.EventRecorder upateLater = Log.Warnings(action: "Later");
private static Log.EventRecorder incomplete = Log.Warnings(action: "Incomplete");
// While these become "Fix-ME" in maroon
private static Log.EventRecorder fixme       = Log.Warnings(action: "fixme");
private static Log.EventRecorder fixMe       = Log.Warnings(action: "fix-me");
private static Log.EventRecorder bug         = Log.Warnings(action: "bug");
private static Log.EventRecorder outstanding = Log.Warnings(action: "Outstanding");
```

Sp, pick your poison.

#### Logging Support

Apart from those already mentioned, you can turn an array of objects into a string of single entries and key-value pairs.

```c#
var more = Log.More("count=", 1, "hello=", "world", "one", "two");
Assert.AreEqual(expected: "count=1,hello=world,one,two", actual: more);
```

Alternatively, you can create a `Dictionary<string,object>` for additional processing. Some analytics like the data so that they can index it.

```c#
var dictionary = Log.ToDictionary(new Log.Contents {
  component = "My Component", action = "Act Now", result = "Success",
  more      = new object[] {"count=", 1, "hello=", "world", "one", "two"}
});
Assert.AreEqual("Act Now", dictionary["action"]);
Assert.AreEqual(1,         dictionary["count"]);
Assert.AreEqual("world",   dictionary["hello"]);
Assert.IsTrue(dictionary.ContainsKey("two"));
```

#### Third Party Logging

If for some reason the log processing is not to your liking or you have a personal analytics or logging package then you can easily add them to the decoupled interface. The first step is to create three methods for messages, warnings and errors. All have the `Log.EventDelegate` signature with a single parameter of type `Contents`.

```c#
public struct Contents {
  public string component, action, result, member, extras;
  public int lineNumber;
  public object[] more;
}
```

Where:

- **component** is the name of the file containing the calling object
- **action** is passed in
- **result** is the message
- **member** is the name of the field created to hold the delegate.
- **extras** is a formatted string containing the other data.
- **more** is an array of objects containing the optional parameters

Here is the Unity implementation. It makes use of the dictionary conversion documented above.

```c#
private static void UnityAnalyticsMessage(Contents ct) =>
  UnityEngine.Analytics.Analytics.CustomEvent(ct.action, ToDictionary(ct));

private static void UnityAnalyticsWarning(Contents contents) =>
  UnityEngine.Analytics.Analytics.CustomEvent("WARNING", ToDictionary(contents));

private static void UnityAnalyticsError(Contents contents) =>
  UnityEngine.Analytics.Analytics.CustomEvent("ERROR", ToDictionary(contents));
```

For a second step, you have a choice. You can either only log to your target or you can add to the logging so that it goes to multiple sources.

```c#
if (UnityEngine.Analytics.Analytics.enabled) {
  MessageEvent += UnityAnalyticsMessage;
  WarningEvent += UnityAnalyticsWarning;
  ErrorEvent   += UnityAnalyticsError;
}
```

If I had chosen to drop the console logs, I would remove the plus to make it a single assignment. Of course for the console, I could enable or disable it with a single flag.

### RichText

Unity supports ***Rich Text*** in UI elements. It is similar to a subset of HTML.

#### Colours (Colors)

Colours can be provided as an RGB hex triplet (#rrggbb) or by name. For code completion ease, `RichText.Colour` or `RichText.Color` has static members for the correct colours. Also, if you want to wrap a ***<color>*** tag around the text, there is a method for that.

```c#
using Askowl.RichText;

Debug.Log((Colour.Tag(Colour.Teal, "My message")));
```

### Objects

`Objects` is a static class of helpers to find and create GameObjects and the like. They are all wrappers to ***slow*** Unity procedures, so cache the results.

#### FindAll

`FindAll<T>` is an extension of `Resources.FindObjectsOfTypeAll<T>`. It will find *all* objects of the specified type with a matching name. Objects can be game objects, prefabs, materials, meshes, textures or similar whether they are enabled or disabled. If the name is empty or null, all resources of type T are returned.

```c#
gameObjects = Objects.FindAll<GameObject>("Text");
Assert.AreEqual(2, gameObjects.Length);
```

#### Find

`Find<T>` uses `FindAll<T>` returns the first or only object of a specific type and name. It is best used with unique object names for a type.

```c#
gameObject = Objects.Find<GameObject>("Text");
Assert.AreEqual("Button Two", gameObject.transform.parent.name);
```

#### Path

`Path` returns the fully qualified path to a GameObject. Use it for logging or navigation in `Components`.

```c#
var gameObject = Objects.Find<GameObject>("Text");
var path       = Objects.Path(gameObject);
Assert.AreEqual("Canvas/Level/Button Two/Text", path);
```

#### CreateGameObject

Unity responds to `new GameObject(name)` by creating a new game object in the root of the current scene. `CreateGameObject` builds on this by moving the game object to be the end of the path given. If it needs to create empty objects on the way then so be it.

```c#
var gameObject  = Objects.CreateGameObject("Canvas/Level Two/Button Three");
var gameObject2 = Objects.Find<GameObject>("Button Three");
Assert.AreEqual(gameObject, gameObject2);
```

### PlayMode Test Runner Support

Askowl Custom Assets have tests for Unity editor PlayMode test-runner. Because this is the core Askowl unity package, it includes the rudimentary support for testing. See the Askowl TestAutomator package for more exhaustive support.

### PlayModeController

PlayModeController is a base class of protected methods used to control actions in the game. Most of the methods run in Coroutines so that control code can wait for them to complete. It uses by *PlayModeTests* and *RemoteControl* classes.

#### Scene

The protected reference to the loaded `Scene` object.

#### LoadScene

Load a scene by name from the scenes list in the build.
Sometimes tests have an exclusive scene to highlight actions challenging to reproduce in game-play. Add to the build, but they include little overhead to the release game.

```c#
  [UnityTest] public IEnumerator AccessCustomAssets() {
    yield return LoadScene("Askowl-CustomAssets-Examples");
    //...
  }
```

#### PushButton

At the least, a player has to push a button to start the game. You can select the button by the name and path in the hierarchy or a `Button` reference. The sparse path elements are separated by one or more slashes and can have missing components. As long as it is unique. For clarity, I use double-slash to indicate missing segments.

```c#
yield return PushButton("Canvas//Show Quote");
// same as
yield return PushButton(Objects.Component<Button>("Show Quote"));
```

The coroutine returns after one tick - giving time for the button events to react.

#### IsDisplayingInGui

By giving the sparse path to a game object that has a renderer, this method checks whether a 2D component is partially or entirely within the view-space.

```c#
var buttonTwo = Components.Find<RectTransform>("Button Two");
Assert.IsTrue(IsDisplayingInUI(buttonTwo));
```

### PlayModeTests

`PlayModeTests` inherits from `PlayModeController` and is the ancestor of real tests within Unity.

It overrides functions to add assertions.

- LoadScene(string name) from PlayModeController
- PushButton(string path) from PlayModeController
- Component<T>(string path...) from Objects.Component<T>(name)
- FindGameObject(string name)
- FindObject<T>(string name) from Objects.Find<T>(name)
- FindObject<T>() from Objects.Find<T>()

#### PlayModeTests.Component

Use this static method rather than `Objects.Component` when testing to retrieve a typed component from a named `GameObject` in the current scene. It marks a failure if we cannot retrieve a component.

```c#
Text results = Component<Text>("Canvas/Results Panel/Text");
```

#### PlayModeTests.FindObject

Use this static method rather than `Objects.Find` when testing to retrieve a named `GameObject` in the current scene. It marks a failure if we cannot retrieve the component.

```c#
Float currentFloat = FindObject<Float>("SampleFloatVariable");
AudioClips  picker = FindObject<AudioClips>();
```

The latter example finds a GameObject called *AudioClips*.

#### PlayModeTests.PushButton

Given the text name of a game component in the scene, treat it as a button and perform the same action as when a player pushed it on the game screen.

#### CheckPattern

Sometimes we need to look at some UI text. We use regular expressions for that.

```c#
CheckPattern(@"^Direct .* at \d\d/\d\d/\d\d\d\d \d\d:\d\d:\d\d", results.text);
```

### A Sample Play Mode Test

Because we sent the slider with a quote, we need to test a range to make sure all is as it should be.

```c#
[UnityTest]
  public IEnumerator TestIntegerAsset() {
    yield return Setup();

    Slider slider = Component<Slider>("Canvas/Integer Asset/Slider");
    slider.value = 0.77f;
    yield return null;

    int buttonValue = int.Parse(ResultsButtonText);
    Assert.GreaterOrEqual(buttonValue, 76);
    Assert.LessOrEqual(buttonValue, 78);
  }
```

### PreviewEditor

Unity custom editors provide additional functionality for the Inspector panel. `PreviewEditor<T>` is a generic that adds a ***Preview*** button to the bottom of the Component.

`AudioClipsEditor` is a custom class that plays a sound when pressing ***Preview***.

```c#
[CustomEditor(typeof(AudioClips))]
public class AudioClipsEditor : PreviewEditor<AudioSource> {
  protected override void Preview() =>
    AudioSource.PlayClipAtPoint(clip: (AudioClips) target, position: Vector3.zero);
}
```

### Range

`Range` is a `Pick` class with serialised low and high values. Calling `Pick()` returns a random value within but inclusive of the range. By default, the range can be between 0 and 1. Using `RangeBounds` allows for different scales.

```c#
[SerializeField] private Range volume = new Range(min: 0.0f, max: 10.0f);
// ...
source.volume = volume.Pick();
```

In this example, the potential range is between 0.0 and 10.0 inclusive, but the sliders are both to the right at 1.0. A range drawer provides better visual editing of ranges in the Inspector.

<img src="RangeDrawer.png" width="50%">

Set range values with the sliders or by typing values on the boxes to the left and right.

### RangeBounds Attribute

For more meaningful ranges we add an attribute called `RangeBounds`.

```c#
[SerializeField, RangeBounds(0, 2)]   private Range pitch    = new Range(1, 2);
[SerializeField, RangeBounds(0, 999)] private Range distance = new Range(110, 800);
```

The width of the range limits how many digits past the decimal point display.

### ScriptableObjects Display Drawer

Scriptable objects provide a valuable resource. By moving code and data out of mono behaviours, we can more easily decouple and test our systems. The problem is that in the default Unity system a scriptable object in a mono behaviour shows up as a resource. You need to select it in the Project view to have the inspector show details.

This script and many thanks to [TheVastBernie](https://forum.unity.com/members/thevastbernie.589052/) for his [script](https://forum.unity.com/threads/editor-tool-better-scriptableobject-inspector-editing.484393/) displays scriptable objects in full in the inspector view of a MonoBehaviour. There is nothing for you to do. When you load ***Able*** all happens automatically.

#### Closed

![ScriptableObjectDrawerClosed](ScriptableObjectDrawerClosed.png)

#### Open

![ScriptableObjectDrawerOpen](ScriptableObjectDrawerOpen.png)

### Set.cs - Unity component implementing selector

`Set `is a generic class that allows you to create a concrete component where you can use `Pick` to get an item from a list.

```c#
[Serializable]
public class SetInstance : Set<AudioClip> {
  public void Play() {
    AudioSource.PlayClipAtPoint(clip: Pick(), position: Vector3.zero);
  }
}
```

This example can play a sound from the list. This is a great way to make a game sound less tedious. Just add an instance as a `[SerializeField]` and fill it from the Inspector.

![SetExample](SetExample.png)

#### Pick from Selector

All classes inheriting from `Set` have a `Pick()` method with two controlling field entries:

- ***cycle***: True to return entries in order, false to get a random selection.
- ***exhaustiveBelow***: If the number of entries in the set is below this value, then while `Pick()` returns a random entry with no repeats. From a list of three, nothing appears random.

These options are available in the editor when you create a custom asset from a `Set`.

#### Set Contents

The `Elements` fields a public `List<T>`, so access it content, but for modifications, use `Add(entry)` and `Remove(entry)` as they rebuild the selector. Overwriting the elements array also trigger a rebuild, as will an explicit `Reset()` call.