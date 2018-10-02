---
title:  FICL (Fast Interactive Configuration Language)
description: FORTH-like language for intelligent app configuration
---
* Table of Contents
{:toc}
# [Executive Summary](http://www.askowl.net/)

# Reference

FICL is a FORTH based language using stack based control and word based commands.

## Arithmetic (+ - / * inc dec)

```
6 2 +   ( n1 n2 -- n3 )   8 expected
6 2 -   ( n1 n2 -- n3 )   4 expected
6 2 *   ( n1 n2 -- n3 )  12 expected
6 2 /   ( n1 n2 -- n3 )   3 expected
12 inc  ( n1 -- n1 )     13 expected
12 dec  ( n1 -- n1 )     11 expected
```

Ref: BridgePlay

## Arrays ([ ])

FICL captures a list of results on the stack for combined processing. It expects a word that takes two words and returns one (reduce) or two (map).

```
[ 1 2 0 ] and              0 expected
[ 11 1 3 ] and             1 expected
[ 1 2 3 ] +                6 expected
[ ' a' ' b' ' c' ] ""      " abc" expected
[ 1 2 ] +                  3 expected
[ 5 ] +                    5 expected
```

Ref: BridgePlayficl.java

## Boolean (and or not = > >= < <=)

```
0 0 and    0 expected
0 1 and    0 expected
1 0 and    0 expected
1 1 and    1 expected

0 0 or     0 expected
0 1 or     1 expected
1 0 or     1 expected
1 1 or     1 expected

1 not      0 expected
0 not      1 expected

12 14 =    0 expected
14 14 =    1 expected

" string 1" " string 2" =  0 expected
" string 1" " string 1" =  1 expected

11 13 >    0 expected
13 11 >    1 expected
13 13 >    0 expected

11 13 <    1 expected
13 11 <    0 expected
13 13 <    0 expected

11 13 >=   0 expected
13 11 >=   1 expected
13 13 >=   1 expected

11 13 <=   1 expected
13 11 <=   0 expected
13 13 <=   1 expected
```

Ref: BridgePlay

## Comments ( ( ) )

```
1 ( inline comment )   1 expected
```

Ref: BridgePlay

## Conditional (if else then)

```
12 0 if 2 - then        ( b1 -- )  12 expected
12 1 if 2 - then        ( b1 -- )  10 expected

12 0 if 2 else 4 then - ( b1 -- )   8 expected
12 1 if 2 else 4 then - ( b1 -- )  10 expected
```

Ref: BridgePlay

## Debugging (.d .s)

**\*.d*** will print out the compiled form of all future words. When they are run it also prints out helpful data such as name, contents and stack depth. It is a toggle.

**\*.s*** will dump the stack contents to the output buffer.

## Define (: return ;)

FICL is extensible by creating words of word lists. Use *return* to leave a word prematurely.

```
: add_two 2 + ; ( n -- n )
3 add_two             5 expected

: test 1 1 if return then 1 + ;
test                  1 expected
```

Ref: BridgePlay

## Loops (begin leave again)

**begin ( -- ) ... leave ( -- ) ... again ( -- )**

Â 

Primary looping mechanism. It loops forever unless leave or are encountered.

Â 

`**begin** words boolean-1 if **leave** then **again**`

Â 

```
5 begin dec dup not if leave then again   0 expected
```

Ref: BridgePlay

## Persistence (:upload ;upload load)

Given a file name, save everything following until ;upload. Use load to reload previously saved data. The functionality is in a separate file so that the persistence mechanism can be changed.

By default persistence is session only. To persist to the file system, use

`ficl.setPersistence(new usdlc.FICL_File(baseDir));`

or implent the interface *FICL_Persistence* to persist across the wire, to a database, or wherever.

```
0 set counter
:upload counter++
  counter inc set counter
;upload
load: counter++
load: counter++
counter 3 expected
```

Ref: BridgePlayBridgePlay

Â 

## Print (.)

Convert the top of stack to printable form and write to output buffer.

## Stack Control (drop dup swap over)

```
1 2 drop     ( a -- )            1 expected
1 dup +      ( a -- a a )        2 expected
1 2 swap /   ( a b -- b a )      2 expected
1 2 over + + ( a b -- a b a )    4 expected
```

Ref: BridgePlay

## Strings (" "")

Note that the leading spaces exists because " is a word. The string is trimmed before saving. Two double-quotes are used to concatenate two strings.

```
" a string"    ( -- s1 )       " a string"  expected
" a string "   ( -- s1 )       " a string " expected
" ab" " cd" "" ( s1 s2 -- s3 ) " abcd"      expected
" ef" 33 ""    ( o1 o2 -- s3)  " ef33"      expected
```

Ref: BridgePlay

## Variables (set: :on-update ref:)

use **\*set*** ( n -- ) to create or assign to a variable from the top of the stack. A variable is a word that pushes it's value onto the stack when referenced.

```
1 set: test_data                test_data 1 expected
test_data 2 + set: test_data    test_data 3 expected
```

One of the benefit of shared data between the underlying application and FICL is that a FICL word can be run when data changes.

```
1 set: my-data
0 set: triggered

:on-update my-data   triggered inc set: triggered ;

triggered 0 expected
2 set: my-data
triggered 1 expected
3 set: my-data
triggered 2 expected
```

Triggers do not accumulate. Re-definition will overwrite prior definitions. Where multiple triggers is desirable, use **ref:** *name* to separate them.

```
:on-update my-data   triggered 2 + set: triggered ;

triggered 2 expected
5 set: my-data
triggered 4 expected ( from 1 trigger )

:on-update my-data ref: t2
  triggered inc set: triggered
;

2 set: my-data
triggered 7 expected ( from 2 triggers )

:on-update my-data ref: t2
  triggered triggered 2 + set: triggered
;

3 set: my-data
triggered 11 expected ( from 2 triggers )
```
