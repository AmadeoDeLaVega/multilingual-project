# Dependent Type

A [[Dependent Type]] is a type that can mention a value.

Example:

```text
Vector Nat 3
```

This can be read as "vectors of natural numbers whose length is 3." The number `3` is a value, but it appears inside the type.

Dependent types let proof assistants state precise claims such as "this sorting function returns a list with the same length as the input."
