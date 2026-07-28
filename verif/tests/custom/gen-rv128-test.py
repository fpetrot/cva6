import os
import re

# main path to the submodule
path_base_test = "rv128-unit-tests/unit"

# destination path for CVA6 test files
path_cva6_test = "rv128-unit-tests/cva6-unit"

# paths to unit tests
path_tests = [
    "unit_tests_i/",
    "unit_tests_m/",
    "unit_tests_c/",
    "unit_tests_b/",
    "unit_tests_csr/",
]

# search all test files in the submodule and copy them to the destination path
for path in path_tests:
    path_submodule = os.path.join(path_base_test, path)
    path_destination = os.path.join(path_cva6_test, path)

    # create destination directory if it doesn't exist
    if not os.path.exists(path_destination):
        os.makedirs(path_destination)

    # copy all test files from submodule to destination
    for root, dirs, files in os.walk(path_submodule):
        for filename in files:
            if filename.endswith(".S"):
                source_file = os.path.join(root, filename)
                destination_file = os.path.join(
                    path_destination, os.path.relpath(source_file, path_submodule)
                )
                destination_dir = os.path.dirname(destination_file)
                if not os.path.exists(destination_dir):
                    os.makedirs(destination_dir)
                with open(source_file, "r") as f:
                    content = f.read()
                with open(destination_file, "w") as f:
                    f.write(content)

# list all test files in the destination path
test_files = []
for path in path_tests:
    path_destination = os.path.join(path_cva6_test, path)
    for root, dirs, files in os.walk(path_destination):
        for filename in files:
            if filename.endswith(".S"):
                test_files.append(os.path.join(root, filename))

# replace all #include lines with #include "rv128_test_macros.h" only once at the top of the file
for file in test_files:
    with open(file, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if not line.startswith("#include"):
            new_lines.append(line)

    new_lines.insert(0, '#include "rv128_test_macros.h"\n#include "utils_test.h"\n')

    with open(file, "w") as f:
        f.writelines(new_lines)

# replace all _start by main in the test files
for file in test_files:
    with open(file, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        new_lines.append(line.replace("_start", "main"))

    with open(file, "w") as f:
        f.writelines(new_lines)

# replace j exit by j _exit in the test files
for file in test_files:
    with open(file, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        new_lines.append(line.replace("j exit", "j _exit"))

    with open(file, "w") as f:
        f.writelines(new_lines)

# replace all .section .text.init,"ax",@progbits by .text.init,"ax",@progbits in the test files
for file in test_files:
    with open(file, "r") as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        new_lines.append(line.replace('.section .text.init,"ax",@progbits', ".text"))

    with open(file, "w") as f:
        f.writelines(new_lines)

# replace all prgchk lines with test macros
for file in test_files:
    with open(file, "r") as f:
        lines = f.readlines()

    # Replace prgchk lines with with test macro
    # e.g. //prgchk reg t0 == 0xffffffffffffffffffffffffffffffff
    new_lines = []
    error_id = 1
    for line in lines:
        if "//prgchk" in line:
            # match the prgchk line with regex
            match_reg_value_eq = re.search(r"//prgchk reg (\w+) == (.+)", line)
            match_reg_value_neq = re.search(r"//prgchk reg (\w+) != (.+)", line)
            match_error = re.search(r"//prgchk err", line)
            match_var = re.search(r"//prgchk var (\w+) == (.+)", line)
            match_reg_reg_eq = re.search(r"//prgchk gdb \$(\w+) == \$?(\w+)", line)
            # match e.g. //prgchk gdb ((unsigned long*) &tab_tst)[0] == 0x1234567890abcdef
            match_gdb_var_eq = re.search(
                r"//prgchk gdb \(\(unsigned long\*\) &(\w+)\)\[(\d+)\] == (.+)",
                line,
            )
            match_gdb_var_neq = re.search(
                r"//prgchk gdb \(\(unsigned long\*\) &(\w+)\)\[(\d+)\] != (.+)",
                line,
            )

            if match_reg_value_eq:
                reg = match_reg_value_eq.group(1)
                expected_value = match_reg_value_eq.group(2)
                # Replace with the test macro
                new_line = (
                    f"    CHK_REG_EQ_VALUE({reg}, {expected_value}, {error_id})\n"
                )
                new_lines.append(new_line)
            elif match_reg_value_neq:
                reg = match_reg_value_neq.group(1)
                expected_value = match_reg_value_neq.group(2)
                # Replace with the test macro
                new_line = (
                    f"    CHK_REG_NEQ_VALUE({reg}, {expected_value}, {error_id})\n"
                )
                new_lines.append(new_line)
            elif match_error:
                new_line = f"    RAISE_ERROR({error_id})\n"
                new_lines.append(new_line)
            elif match_var:
                var = match_var.group(1)
                expected_value = match_var.group(2)

                if expected_value.startswith("0x"):
                    if len(expected_value) > 18:
                        new_line = f"    CHK_EQ_MEM_VALUE_Q({var}, {expected_value}, {error_id})\n"
                    elif len(expected_value) > 10:
                        new_line = f"    CHK_EQ_MEM_VALUE_D({var}, {expected_value}, {error_id})\n"
                    else:
                        new_line = f"    CHK_EQ_MEM_VALUE_W({var}, {expected_value}, {error_id})\n"
                else:
                    new_line = (
                        f"    CHK_EQ_MEM_VALUE_W({var}, {expected_value}, {error_id})\n"
                    )

                new_lines.append(new_line)
            elif match_reg_reg_eq:
                reg1 = match_reg_reg_eq.group(1)
                reg2 = match_reg_reg_eq.group(2)
                new_line = f"    CHK_EQ_REG_REG({reg1}, {reg2}, {error_id})\n"
                new_lines.append(new_line)
            elif match_gdb_var_eq:
                var = match_gdb_var_eq.group(1)
                index = match_gdb_var_eq.group(2)
                expected_value = match_gdb_var_eq.group(3)

                if expected_value.startswith("0x"):
                    if len(expected_value) > 18:
                        new_line = f"    CHK_EQ_MEM_VALUE_Q({var} + {index} * 8, {expected_value}, {error_id})\n"
                    elif len(expected_value) > 10:
                        new_line = f"    CHK_EQ_MEM_VALUE_D({var} + {index} * 4, {expected_value}, {error_id})\n"
                    else:
                        new_line = f"    CHK_EQ_MEM_VALUE_W({var} + {index} * 4, {expected_value}, {error_id})\n"
                else:
                    new_line = f"    CHK_EQ_MEM_VALUE_W({var} + {index} * 4, {expected_value}, {error_id})\n"

                new_lines.append(new_line)
            elif match_gdb_var_neq:
                var = match_gdb_var_neq.group(1)
                index = match_gdb_var_neq.group(2)
                expected_value = match_gdb_var_neq.group(3)

                if expected_value.startswith("0x"):
                    if len(expected_value) > 18:
                        new_line = f"    CHK_NEQ_MEM_VALUE_Q({var} + {index} * 8, {expected_value}, {error_id})\n"
                    elif len(expected_value) > 10:
                        new_line = f"    CHK_NEQ_MEM_VALUE_D({var} + {index} * 4, {expected_value}, {error_id})\n"
                    else:
                        new_line = f"    CHK_NEQ_MEM_VALUE_W({var} + {index} * 4, {expected_value}, {error_id})\n"
                else:
                    new_line = f"    CHK_NEQ_MEM_VALUE_W({var} + {index} * 4, {expected_value}, {error_id})\n"

                new_lines.append(new_line)
            else:
                # panic
                raise Exception(f"Unknown prgchk line: {line}")

            error_id += 1
        else:
            new_lines.append(line)

    # Write the modified lines back to the file
    with open(file, "w") as f:
        f.writelines(new_lines)
