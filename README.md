# Juliet Test Suite for C/C++

This is the Juliet Test Suite for C/C++ version 1.3 from https://samate.nist.gov/SARD/testsuite.php augmented with a build system for Unix-like OSes that supports automatically building test cases into individual executables and running those tests. The build system originally provided with the test suite supports building all test cases for a particular [CWE](https://cwe.mitre.org/) into a monolithic executable. Building individual test cases supports the evaluation of projects like [CHERI](https://www.cl.cam.ac.uk/research/security/ctsrd/cheri/) that facilitate memory safety for C/C++ programs at runtime. 

Testcases are organized by CWE in the `testcases` subdirectory. `juliet.py` is the main script that supports building and running individual test cases - individual CWEs or the entire test suite can be targeted. To build executables, `juliet.py` copies `CMakeLists.txt` into the directories for targeted CWEs and runs cmake followed by make. Output appears by default in a `bin` subdirectory. Each targeted CWE has a `bin/CWEXXX` directory that is further divided into `bin/CWEXXX/good` and `bin/CWEXXX/bad` subdirectories. For each test case, a "good" binary that does not contain the error is built and placed into the good subdirectory and a "bad" binary that contains the error is built and placed into the bad subdirectory.

To run executables after they are built, `juliet.py` invokes the `juliet-run.sh` script, which is copied to the `bin` subdirectory during the build. It records exit codes in `bin/CWEXXX/good.run` and `bin/CWEXXX/bad.run`. Executables are run with a timeout so that test cases depending on user input timeout with exit code 124.

**Note:** Juliet C++ test cases that use namespace std and the bind() socket function didn't compile under c++11, which introduces std::bind(). This version of the test suite has replaced `bind()` calls in C++ source files with calls to `::bind()`.

## Running Sample

Clean, build, compile, run tests.

``` shell
python3 juliet.py 121 122 124 126 127 -o ./bin -c -g -m -r
```

Statistical test results.

``` shell
python3 parse-cwe-status.py ./bin/CWE126/bad.run
```

A example of statistical results is as follows.

``` shell
===== EXIT STATUS =====
OK            25
1            647

===== DATAFLOW VARIANTS =====
 VAR         OK         1
  1:          1        14
  2:          1        14
...

===== FUNCTIONAL VARIANTS =====
                                      OK         1
CWE129_fgets                           0        48
CWE129_fscanf                          0        48
CWE129_large                          25        23
char_alloca_loop                       0        40
char_alloca_memcpy                     0        40
char_alloca_memmove                    0        40
...
```

## Modify dataset

In order to ensure that the same test results can be obtained every time JTS is run as much as possible, the impact of the random number rand() needs to be removed, so the return value of globalReturnsTrueOrFalse() is changed to `1` (JTS flow variant 12 will call this function).

``` C
int globalReturnsTrueOrFalse() 
{
    // return (rand() % 2);
    return 1;
}
```

## Compiler settings

Set the compiler and enable the AddressSanitizer compilation option.

``` bash
# Set the C and C++ compilers
set(CMAKE_C_COMPILER "/usr/bin/clang-4.0")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++-4.0")

project("juliet-c-${CWE_NAME}")

# Set the C and C++ compiler flags
set(CMAKE_C_FLAGS "-fsanitize=address -fsanitize-recover=address")
set(CMAKE_CXX_FLAGS "-fsanitize=address -fsanitize-recover=address")
```

## Filter dataset

In order to ensure that the same test results can be obtained every time JTS is run as much as possible, the following three tests are filtered out:
1. Tests whose names contain `socket` need to be run on both the client and the server. They are not suitable for AddressSanitizer tests and will bring uncertain timeouts, resulting in inconsistent test results.
2. Tests whose names contain `rand` will also cause inconsistent test results due to the existence of random numbers.
3. Tests whose names contian `CWE170_char_*` prints a string without the terminating character `\0`, which will produce random overflow.

``` bash
if echo "$TESTCASE" | grep -q "socket"
then continue
fi

if echo "$TESTCASE" | grep -q "rand"
then continue
fi

if echo "$TESTCASE" | grep -q "CWE170"
then continue
fi
```

## Process the datasets that require input

It is consistent with [test script of FloatZone](https://github.com/vusec/instrumentation-infra/blob/5bfbf68e0cfe46cf9600a0bcf4fa7a4a2fd80e48/infra/targets/juliet.py). For general input, `11` is uniformly passed in by reading the file. For underflow reading and writing (CWE124, CWE127) Pass in `-1` uniformly by reading files.

``` bash
if [ "$CWDID" = "124" ] || [ "$CWDID" = "127" ]
then
    timeout "${TIMEOUT}" "${TESTCASE_PATH}" < "${INPUT_FILE_124_127}"
else
    timeout "${TIMEOUT}" "${TESTCASE_PATH}" < "${INPUT_FILE}"
fi
```

## Improve the compatibility of statistics scripts

The statistical script uses some data structures of higher versions of python3, which are not supported by lower versions of python3. Additional packages need to be imported and the original data structures replaced.

``` python
from typing import List, Dict, Tuple
...
def do_parsing(filename: str) -> Tuple[str, Dict[int, List[int]], Dict[str, Dict[int, int]]]:
    ...
```