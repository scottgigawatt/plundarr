#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# __init__.pyi: Type the Atheris API used by the optional native fuzzing harness.
#

"""Describe only the fuzz APIs used here; Atheris stays in the fuzzing image."""

from collections.abc import Callable
from contextlib import AbstractContextManager
from typing import NoReturn

class FuzzedDataProvider:
    """Consume bounded strings from one fuzzer-provided byte sequence."""

    def __init__(self, data: bytes) -> None: ...
    def ConsumeUnicodeNoSurrogates(self, count: int) -> str: ...

def instrument_imports() -> AbstractContextManager[None]: ...
def Setup(arguments: list[str], target: Callable[[bytes], None]) -> None: ...
def Fuzz() -> NoReturn: ...
