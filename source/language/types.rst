.. role:: raw-latex(raw)
   :format: latex
..

Types and Casting
=================

Generalities
------------

Variable identifiers must begin with a letter [A-Za-z], an underscore or an element from the Unicode character categories
Lu/Ll/Lt/Lm/Lo/Nl :cite:`noauthorUnicodeNodate`. The set of permissible
continuation characters consists of all members of the aforementioned character
sets with the addition of decimal numerals [0-9]. Variable identifiers may not
override a reserved identifier.

In addition to being assigned values within a program, all of the classical
types can be initialized on declaration. Any classical variable or Boolean that is not explicitly
initialized is undefined. Classical types can be mutually cast to one another using the typename.
See :ref:`castingSpecifics` for more details on casting.

Declaration and initialization must be done one variable at a time for both quantum and classical
types. Comma seperated declaration/initialization (``int x, y, z``) is NOT allowed for any type. For
example, to declare a set of qubits one must do

.. code-block:: c

   qubit q0;
   qubit q1;
   qubit q2;

and to declare a set of classical variables

.. code-block:: c

   int[32] a;
   float[32] b = 5.5;
   bit[3] c;
   bool my_bool = false;

We use the notation ``s:m:f`` to denote the width and precision of fixed point numbers,
where ``s`` is the number of sign bits, ``m`` is the number of integer bits, and ``f`` is the
number of fractional bits. It is necessary to specify low-level
classical representations since OpenQASM operates at the intersection of
gates/analog control and digital feedback and we need to be able to
explicitly transform types to cross these boundaries. Classical types
are scoped to the braces within which they are declared.

Quantum types
-------------

Qubits
~~~~~~

There is a quantum bit (``qubit``) type that is interpreted as a reference to a
two-level subsystem of a quantum state. The statement ``qubit name;``
declares a reference to a quantum bit. These qubits are referred
to as "virtual qubits" (in distinction to "physical qubits" on
actual hardware; see below). The statement ``qubit[size] name;``
declares a quantum register with ``size`` qubits.
Sizes must always be constant positive integers. The label ``name[j]``
refers to a qubit of this register, where
:math:`j\in \{0,1,\dots,\mathrm{size}(\mathrm{name})-1\}` is an integer.
Quantum registers are static arrays of qubits
that cannot be dynamically resized.

The keyword ``qreg`` is included
for backwards compatibility and will be removed in the future.

Qubits are initially in an undefined state. A quantum ``reset`` operation is one
way to initialize qubit states.

All qubits are global variables.
Qubits cannot be declared within gates or subroutines. This simplifies OpenQASM
significantly since there is no need for quantum memory management.
However, it also means that users or compiler have to explicitly manage
the quantum memory.

Physical Qubits
~~~~~~~~~~~~~~~

While program qubits can be named, hardware qubits are referenced only
by the syntax ``$[NUM]``. For an ``n`` qubit system, we have physical qubit
references given by ``$0``, ``$1``, ..., ``$n-1``. These qubit types are
used in lower parts of the compilation stack when emitting physical
circuits. Physical qubits must not be declared and they are, as all the qubits, global variables.

.. code-block:: c
   :force:

   // Declare a qubit
   qubit gamma;
   // Declare a qubit with a Unicode name
   qubit γ;
   // Declare a qubit register with 20 qubits
   qubit[20] qubit_array;
   // CNOT gate between physical qubits 0 and 1
   CX $0, $1;

Classical types
---------------

Classical bits and registers
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

There is a classical bit type that takes values 0 or 1. Classical
registers are static arrays of bits. The classical registers model part
of the controller state that is exposed within the OpenQASM program. The
statement ``bit name;`` declares a classical bit, and or ``bit[size] name;`` declares a register of
``size`` bits. The label ``name[j]`` refers to a bit of this register, where :math:`j\in
\{0,1,\dots,\mathrm{size}(\mathrm{name})-1\}` is an integer.

Bit registers may also be declared as ``creg name[size]``. This is included for backwards
compatibility and may be removed in the future.

For convenience, classical registers can be assigned a text string
containing zeros and ones of the same length as the size of the
register. It is interpreted to assign each bit of the register to
corresponding value 0 or 1 in the string, where the least-significant
bit is on the right.

.. code-block:: c

   // Declare a register of 20 bits
   bit[20] bit_array;
   // Declare and assign a rgister of bits with decimal value of 15
   bit[8] name = "00001111";

Integers
~~~~~~~~

There are n-bit signed and unsigned integers. The statements ``int[size] name;`` and ``uint[size] name;`` declare
signed 1:n-1:0 and unsigned 0:n:0 integers of the given size. The sizes
are always explicitly part of the type; there is no implicit width for
classical types in OpenQASM. Because register indices are integers, they
can be cast from classical registers containing measurement outcomes and
may only be known at run time. An n-bit classical register containing
bits can also be reinterpreted as an integer, and these types can be
mutually cast to one another using the type name, e.g. ``int[16](c)``. As noted, this
conversion will be done assuming little-endian bit ordering. The example
below demonstrates how to declare, assign and cast integer types amongst
one another.

.. code-block:: c

   // Declare a 32-bit unsigned integer
   uint[32] my_uint = 10;
   // Declare a 16 bit signed integer
   int[16] my_int;
   my_int = int[16](my_uint);

Floating point numbers
~~~~~~~~~~~~~~~~~~~~~~

IEEE 754 floating point registers may be declared with ``float[size] name;``, where ``float[64]`` would
indicate a standard double-precision float. Note that some hardware
vendors may not support manipulating these values at run-time.

.. code-block:: c
   :force:

   // Declare a single-precision 32-bit float
   float[32] my_float = π;

Fixed-point angles
~~~~~~~~~~~~~~~~~~

Fixed-point angles are interpreted as 2π times a 0:0:n
fixed-point number. This represents angles in the interval
:math:`[0,2\pi)` up to an error :math:`\epsilon\leq \pi/2^{n-1}` modulo
2π. The statement ``angle[size] name;`` declares an n-bit angle. OpenQASM3
introduces this specialized type because of the ubiquity of this angle
representation in phase estimation circuits and numerically controlled
oscillators found in hardware platform. Note that defining gate
parameters with ``angle`` types may be necessary for those parameters to be
compatible with run-time values on some platforms.

.. code-block:: c
   :force:

   // Declare an angle with 20 bits of precision and assign it a value of π/2
   angle[20] my_angle = π / 2;
   float[32] float_pi = π;
   // equivalent to pi_by_2 up to rounding errors
   angle[20](float_pi / 2);

Complex numbers
~~~~~~~~~~~~~~~

Complex numbers may be declared as ``complex[type[size]] name``, for a numeric OpenQASM classical type
``type`` (``int``, ``float``, ``angle``) and a number of bits ``size``. The real
and imaginary parts of the complex number are ``type[size]`` types. For instance, ``complex[float[32]] c``
would declare a complex number with real and imaginary parts that are 32-bit floating point numbers. The
``im`` keyword defines the imaginary number :math:`sqrt(-1)`. ``complex[type[size]]`` types are initalized as
``a + b im``, where ``a`` and ``b`` must be of the same type as ``type[size]``. ``b`` must occur to the
left of ``im`` and the two can only be seperated by spaces/tabs (or nothing at all).

.. code-block::

   complex[float[64]] c;
   c = 2.5 + 3.5im; // 2.5, 3.5 are resolved to be ``float[64]`` types
   complex[float[64]] d = 2.0+sin(π) + 3.1*5.5 im;
   complex[int[32]] f = 2 + 5 im; // 2, 5 are resolved to be ``int[32]`` types

Boolean types
~~~~~~~~~~~~~

There is a Boolean type ``bool name;`` that takes values ``true`` or ``false``. Qubit measurement results
can be converted from a classical ``bit`` type to a Boolean using ``bool(c)``, where 1 will
be true and 0 will be false.

.. code-block:: c

   bit my_bit = 0;
   bool my_bool;
   // Assign a cast bit to a boolean
   my_bool = bool(my_bit);

Const values
~~~~~~~~~~~~

To support mathematical expressions, immutable constants of any classical type
may be declared using the type modifier ``const``. On
declaration, they take their assigned value and cannot be redefined
within the same scope. These are constructed using an in-fix notation
and scientific calculator features such as scientific notation, real
arithmetic, logarithmic, trigonometric, and exponential functions
including ``sqrt``, ``floor``, ``ceiling``, ``log``, ``pow``, ``div``, ``mod`` and the built-in constant π. The
statement ``const type name = expression;`` defines a new constant. The expression on the right hand side
has a similar syntax as OpenQASM 2 parameter expressions; however,
previously defined constants can be referenced in later variable
declarations. ``const`` values are compile-time constants, allowing the
compiler to do constant folding and other such optimizations. Scientific
calculator-like operations on run-time values require extern function
calls as described later and are not available by default. Real
constants can be cast to other types, just like other values.

A standard set of built-in constants which are included in the default
namespace are listed in table `1 <#tab:real-constants>`__. These constants
are all of type ``float[64]``.

.. code-block:: c
   :force:

   // Declare a constant
   const int my_const = 1234;
   // Scientific notation is supported
   const int[64] another_const = 1e12;
   // Constant expressions are supported
   const float[64] pi_by_2 = π / 2;
   // Constants may be cast to real-time values
   float[32] pi_by_2_val = float[32](pi_by_2)

.. container::
   :name: tab:real-constants

   .. table:: [tab:real-constants] Built-in real constants in OpenQASM3 of type ``float[64]``.

      +-------------------------------+--------------+--------------+---------------------+
      | Constant                      | Alphanumeric | Unicode      | Approximate Base 10 |
      +===============================+==============+==============+=====================+
      | Pi                            | pi           | π            | 3.1415926535...     |
      +-------------------------------+--------------+--------------+---------------------+
      | Tau                           | tau          | τ            | 6.283185...         |
      +-------------------------------+--------------+--------------+---------------------+
      | Euler’s number                | euler        | ℇ            | 2.7182818284...     |
      +-------------------------------+--------------+--------------+---------------------+

Note that `e` is a valid identifier. `e/E` are also used in scientific notation where appropriate.

Mathematical functions available for constant initialization
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

In addition to simple arithmetic functions used in expressions initializing constants,
OpenQASM 3 offers the following built-in mathematical operators followed by
their argument expression in parentheses:

.. container::
   :name: tab:built-in-math

   .. table:: Built-in mathematical functions in OpenQASM3.

      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | Function | Input Range/Type, [...]           | Output Range/Type                    | Notes                                  |
      +==========+===================================+======================================+========================================+
      | arccos   | ``float`` on :math:`[-1, 1]`      | ``float`` on :math:`[0, \pi]`        |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | arcsin   | ``float`` on :math:`[-1, 1]`      | ``float`` on :math:`[-\pi/2, \pi/2]` |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | arctan   | ``float``                         | ``float`` on :math:`[-\pi/2, \pi/2]` |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | ceiling  | ``float``                         | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | cos      | (``float`` or ``angle``)          | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | exp      | ``float``                         | ``float``                            |                                        |
      |          |                                   |                                      |                                        |
      |          | ``complex``                       | ``complex``                          |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | floor    | ``float``                         | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | log      | ``float``                         | ``float``                            | Logarithm base :math:`e`               |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | mod      | ``int``, ``int``                  | ``int``                              |                                        |
      |          |                                   |                                      |                                        |
      |          | ``float``, (``int`` or ``float``) | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | popcount | ``bit[_]``, ``uint``              | ``uint``                             |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | pow      | ``int``, ``uint``                 | ``int``                              |                                        |
      |          |                                   |                                      |                                        |
      |          | ``float``, ``float``              | ``float``                            | For floating-point and complex values, |
      |          |                                   |                                      | the principal value is returned.       |
      |          | ``complex``, ``complex``          | ``complex``                          |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | rotl     | ``bit[n]``, (``int`` or ``uint``) | ``bit[n]``                           |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | rotr     | ``bit[n]``, (``int`` or ``uint``) | ``bit[n]``                           |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | sin      | (``float`` or ``angle``)          | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | sqrt     | ``float``                         | ``float``                            | Returns the principal root.            |
      |          |                                   |                                      |                                        |
      |          | ``complex``                       | ``complex``                          |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+
      | tan      | (``float`` or ``angle``)          | ``float``                            |                                        |
      +----------+-----------------------------------+--------------------------------------+----------------------------------------+

Arrays
------

Statically-sized arrays of values can be created and initialized, and individual elements
can be accessed, using the following general syntax:

.. code-block:: c

   array[int[32], 5] myArray = {0, 1, 2, 3, 4};
   array[float[32], 3, 2] multiDim = {{1.1, 1.2}, {2.1, 2.2}, {3.1, 3.2}};

   int[32] firstElem = myArray[0]; // 0
   int[32] lastElem = myArray[4]; // 4
   int[32] alsoLastElem = myArray[-1]; // 4
   float[32] firstLastElem = multiDim[0, 1]; // 1.2
   float[32] lastLastElem = multiDim[2, 1]; // 3.2
   float[32] alsoLastLastElem = multiDim[-1, -1]; // 3.2

   myArray[4] = 10; // myArray == {0, 1, 2, 3, 10}
   multiDim[0, 0] = 0.0; // multiDim == {{0.0, 1.2}, {2.1, 2.2}, {3.1, 3.2}}
   multiDim[-1, 1] = 0.0; // multiDim == {{0.0, 1.2}, {2.1, 2.2}, {3.1, 0.0}}

Arrays *cannot* be declared inside the body of a function or gate. All arrays
*must* be declared within the global scope of the program.
Indexing of arrays is n-based *i.e.*, negative indices are allowed.
The index ``-1`` means the last element of the array, ``-2`` is the second to
last, and so on, with ``-n`` being the first element of an n-element array.
Multi-dimensional arrays (as in the example above) are allowed, with a maximum
of 7 total dimensions. The subscript operator ``[]`` is used for element access,
and for multi-dimensional arrays subarray accesses can be specified using a
comma-delimited list of indices (*e.g.* ``myArr[1, 2, 3]``), with the outer
dimension specified first.

For interoperability, the standard
ways of declaring quantum registers and bit registers are equivalent to the
array syntax version (*i.e.* ``qubit[5] q1;`` is the same as
``array[qubit, 5] q1;``).
Assignment to elements of arrays, as in the examples above, acts as expected,
with the left-hand side of the assignment operating as a reference, thereby
updating the values inside the original array. For multi-dimensional arrays,
the shape and type of the assigned value must match that of the reference.

.. code-block:: c

   array[int[8], 3] aa;
   array[int[8], 4, 3] bb;

   bb[0] = aa; // all of aa is copied to first element of bb
   bb[0, 1] = aa[2] // last element of aa is copied to one element of bb

   bb[0] = 1 // error - shape mismatch

Arrays may be passed to subroutines and externs. For more details, see 
:any:`arrays-in-subroutines`.

Types related to timing
-----------------------

Duration
~~~~~~~~

We introduce a ``duration`` type to express timing.
Durations are numbers with a unit of time. ``ns, μs, us, ms, and s`` are used for SI time
units. ``dt`` is a backend-dependent unit equivalent to one waveform sample.
``durationof()`` is an intrinsic function used to reference the
duration of a calibrated gate.

.. code-block:: c

   duration one_second = 1000ms;
   duration thousand_cycles = 1000dt;
   duration c = durationof({x $3;});

``duration`` is further discussed in :any:`duration-and-stretch`

Stretch
~~~~~~~

We further introduce a ``stretch`` type which is a sub-type of ``duration``. ``stretch`` types
have variable non-negative duration that is permitted to grow as necessary
to satisfy constraints. Stretch variables are resolved at compile time
into target-appropriate durations that satisfy a user’s specified design
intent.

``stretch`` is further discussed in :any:`duration-and-stretch`

Aliasing
--------

The ``let`` keyword allows quantum bits and registers to be referred to by
another name as long as the alias is in scope.

.. code-block:: c

  qubit[5] q;
  // myreg[0] refers to the qubit q[1]
  let myreg = q[1:4];

Index sets and slicing
----------------------

Register concatenation and slicing
----------------------------------

Two or more registers of the same type (i.e. classical or quantum) can
be concatenated to form a register of the same type whose size is the
sum of the sizes of the individual registers. The concatenated register
is a reference to the bits or qubits of the original registers. The
statement ``a ++ b`` denotes the concatenation of registers ``a`` and ``b``. A register cannot
be concatenated with any part of itself.

Classical and quantum registers can be indexed in a way that selects a
subset of (qu)bits, i.e. by an index set. A register so indexed is
interpreted as a register of the same type but with a different size.
The register slice is a reference to the original register. A register
cannot be indexed by an empty index set.

Similarly, classical arrays can be indexed using index sets. See :any:`array-slicing`.

An index set can be specified by a single integer (signed or unsigned), a
comma-separated list of integers contained in braces ``{a,b,c,…}``, or a range.
Ranges are written as ``a:b`` or
``a:c:b`` where ``a``, ``b``, and ``c`` are integers (signed or unsigned).
The range corresponds to the set :math:`\{a, a+c, a+2c, \dots, a+mc\}`
where :math:`m` is the largest integer such that :math:`a+mc\leq b` if
:math:`c>0` and :math:`a+mc\geq b` if :math:`c<0`. If :math:`a=b` then
the range corresponds to :math:`\{a\}`. Otherwise, the range is the
empty set. If :math:`c` is not given, it is assumed to be one, and
:math:`c` cannot be zero. Note the index sets can be defined by
variables whose values may only be known at run time.

.. code-block:: c

   qubit[2] one;
   qubit[10] two;
   // Aliased register of twelve qubits
   let concatenated = one ++ two;
   // First qubit in aliased qubit array
   let first = concatenated[0];
   // Last qubit in aliased qubit array
   let last = concatenated[-1];
   // Qubits zero, three and five
   let qubit_selection = two[{0, 3, 5}];
   // First six qubits in aliased qubit array
   let sliced = concatenated[0:6];
   // Every second qubit
   let every_second = concatenated[0:2:12];
   // Using negative ranges to take the last 3 elements
   let last_three = two[-4:-1];
   // Concatenate two alias in another one
   let both = sliced ++ last_three;

Classical value bit slicing
---------------------------

A subset of classical values (int, uint, and angle) may be accessed at the bit
level using index sets similar to register slicing. The bit slicing operation
always returns a bit array of size equal to the size of the index set.

.. code-block:: c

   int[32] myInt = 15; // 0xF or 0b1111
   bit[1] lastBit = myInt[0]; // 1
   bit[1] signBit = myInt[31]; // 0
   bit[1] alsoSignBit = myInt[-1]; // 0

   bit[16] evenBits = myInt[0:2:31]; // 3
   bit[16] upperBits = myInt[-16:-1];
   bit[16] upperReversed = myInt[-1:-16];

   myInt[4:7] = "1010"; // myInt == 0xAF

Bit-level access is still possible with elements of arrays. It is suggested that
multi-dimensional access be done using the comma-delimited version of the
subscript operator to reduce confusion. With this convention nearly all
instances of multiple subscripts ``[][]`` will be bit-level accesses of array
elements.

.. code-block:: c

   array[int[32], 5] intArr = {0, 1, 2, 3, 4};
   // Access bit 0 of element 0 of intArr and set it to 1
   intArr[0][0] = 1;
   // lowest 5 bits of intArr[4] copied to b
   bit[5] b = intArr[4][0:4];

.. _array-slicing:

Array concatenation and slicing
-------------------------------

Two or more classical arrays of the same fundamental type can be
concatenated to form an array of the same type whose size is the
sum of the sizes of the individual arrays. Unlike with qubit registers, this operation
copies the contents of the input arrays to form the new (larger) array. This means that
arrays *can* be concatenated with themselves. However, the array concatenation
operator is forbidden to be used directly in the argument list of a subroutine
or extern call. If a concatenated array is to be passed to a subroutine then it
should be explicitly declared and assigned the concatenation.

.. code-block:: c

   array[int[8], 2] first = {0, 1};
   array[int[8], 3] second = {2, 3, 4};

   array[int[8], 5] concat = first ++ second;
   array[int[8], 4] selfConcat = first ++ first;

   array[int[8], 2] secondSlice = second[1:2]; // {3, 4}

   // slicing with assignment
   second[1:2] = first[0:1]; // second == {2, 0, 1}

   array[int[8], 4] third = {5, 6, 7, 8};
   // combined slicing and concatenation
   selfConcat[0:3] = first[0:1] ++ third[1:2];
   // selfConcat == {0, 1, 6, 7}

   subroutine_call(first ++ third) // forbidden
   subroutine_call(selfConcat) // allowed

Arrays can be sliced just like quantum registers using index sets. Slicing uses
the subscript operator ``[]``, but produces an array (or reference in the case
of assignment) with the same number of dimensions as the given identifier.
Array slicing is syntactic sugar for concisely expressing for loops over
multi-dimensional arrays.
For sliced assignments, as with non-sliced assignments, the shapes and types of
the slices must match.

.. code-block:: c

   int[8] scalar;
   array[int[8], 2] oneD;
   array[int[8], 3, 2] twoD; // 3x2
   array[int[8], 3, 2] anotherTwoD; // 3x2
   array[int[8], 4, 3, 2] threeD; // 4x3x2
   array[int[8], 2, 3, 4] anotherThreeD; // 2x3x4

   threeD[0, 0, 0] = scalar; // allowed
   threeD[0, 0] = oneD; // allowed
   threeD[0] = twoD; // allowed

   threeD[0] = oneD; // error - shape mismatch
   threeD[0, 0] = scalar // error - shape mismatch
   threeD = anotherThreeD // error - shape mismatch

   twoD[1:2] = anotherTwoD[0:1]; // allowed
   twoD[1:2, 0] = anotherTwoD[0:1, 1]; // allowed

.. _castingSpecifics:

Casting specifics
-----------------

The classical types are divided into the 'standard' classical types (bool, int, 
uint, and float) that exist in languages like C, and the 'special' classical 
types (bit, angle, duration, and stretch) that do not.

In general, for any cast between standard types that results in loss of 
precision, if the source value is larger than can be represented in the target 
type, the exact behavior is implementation specific and must be documented by 
the vendor.

Allowed casts
~~~~~~~~~~~~~

.. role:: rbg
.. role:: gbg
.. role:: center

+--------------+--------------------------------------------------------------------------------------------------------+
|              |                                       :center:`Casting To`                                             |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| Casting From | bool       | int        | uint       | float       | angle      | bit        | duration   | qubit      |
+==============+============+============+============+=============+============+============+============+============+
| **bool**     | :center:`-`| :gbg:`Yes` | :gbg:`Yes` | :gbg:`Yes`  | :rbg:`No`  | :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **int**      | :gbg:`Yes` | :center:`-`| :gbg:`Yes` | :gbg:`Yes`  | :rbg:`No`  | :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **uint**     | :gbg:`Yes` | :gbg:`Yes` | :center:`-`| :gbg:`Yes`  | :rbg:`No`  | :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **float**    | :gbg:`Yes` | :gbg:`Yes` | :gbg:`Yes` | :center:`-` | :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **angle**    | :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  | :rbg:`No`   | :center:`-`| :gbg:`Yes` | :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **bit**      | :gbg:`Yes` | :gbg:`Yes` | :gbg:`Yes` | :rbg:`No`   | :gbg:`Yes` | :center:`-`| :rbg:`No`  | :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **duration** | :rbg:`No`  | :rbg:`No`  | :rbg:`No`  | :rbg:`No*`  | :rbg:`No`  | :rbg:`No`  | :center:`-`| :rbg:`No`  |
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+
| **qubit**    | :rbg:`No`  | :rbg:`No`  | :rbg:`No`  | :rbg:`No`   | :rbg:`No`  | :rbg:`No`  | :rbg:`No`  | :center:`-`|
+--------------+------------+------------+------------+-------------+------------+------------+------------+------------+

\*Note: ``duration`` values can be converted to ``float`` using the division operator. See :ref:`divideDuration`

Casting from bool
~~~~~~~~~~~~~~~~~

``bool`` values cast from ``false`` to ``0.0`` and from ``true`` to ``1.0`` or 
an equivalent representation. ``bool`` values can only be cast to ``bit[1]`` 
(a single bit), so explicit index syntax must be given if the target ``bit``
has more than 1 bit of precision.

Casting from int/uint
~~~~~~~~~~~~~~~~~~~~~

``int[n]`` and ``uint[n]`` values cast to the standard types mimicking C99
behavior. Casting to ``bool`` values follows the convention ``val != 0``.
As noted above, if the value is too large to be represented in the
target type the result is implementation-specific. However, 
casting between ``int[n]`` and ``uint[n]`` is expected to preserve the bit
ordering, specifically it should be the case that ``x == int[n](uint[n](x))``
and vice versa. Casting to ``bit[m]`` is only allowed when ``m==n``. If the target
``bit`` has more or less precision, then explicit slicing syntax must be given.
As noted, the conversion is done assuming a little-endian 2's complement 
representation.

Casting from float
~~~~~~~~~~~~~~~~~~

``float[n]`` values cast to the standard types mimicking C99 behavior (*e.g.* 
discarding the fractional part for integer-type targets). As noted above, 
if the value is too large to be represented in the 
target type the result is implementation-specific. 
Casting a ``float`` value to an ``angle[m]`` is accomplished by first 
performing a modulo 2π operation on the float value. The resulting value 
is then converted to the nearest ``angle[m]`` possible. In the event of a 
tie between two possible nearest values the result is the one with an even 
least significant bit (*i.e.* round to nearest, ties to even).

Casting from angle
~~~~~~~~~~~~~~~~~~

``angle[n]`` values cast to ``bool`` using the convention ``val != 0.0``. 
Casting to ``bit[m]`` values is only allowed when 
``n==m``, otherwise explicit slicing syntax must be provided.

When casting between angles of differing precisions (``n!=m``): if the target 
has more significant bits, then the value is padded with ``m-n`` least 
significant bits of ``0``; if the target has fewer significant bits, then 
there are two acceptable behaviors that can be supported by compilers: 
rounding and truncation. For rounding the value is rounded to the nearest 
value, with ties going to the value with the even least significant bit.
Trunction is likely to have more hardware support. This behavior can be
controlled by the use of a ``#pragma``.

Casting from bit
~~~~~~~~~~~~~~~~

``bit[n]`` values cast to ``bool`` using the convention ``val != 0``. Casting to 
``int[m]`` or ``uint[m]`` is done assuming a little endian 2's complement 
representation, and is only allowed when ``n==m``, otherwise explicit slicing 
syntax must be given. Likewise, ``bit[n]`` can only be cast to ``angle[m]`` 
when ``n==m``, in which case an exact per-bit copy is done using little-endian 
bit order. Finally, casting between bits of differing precisions is not 
allowed, explicit slicing syntax must be given.

.. _divideDuration:

Converting duration to other types
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Casting from or to duration values is not allowed, however, operations on 
durations that produce values of different types is allowed. For example, 
dividing a duration by a duration produces a machine-precision ``float``.

.. code-block:: c

   duration one_ns = 1ns;
   duration a = 500ns;
   float a_in_ns = a / one_ns;  // 500.0

   duration one_s = 1s;
   float a_in_s = a / one_s; // 5e-7

