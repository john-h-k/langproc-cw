#!/usr/bin/env bash

jcc="../../jcc/build/jcc"
jcc_include="../../c-testsuite/jcc_include"
tests="../compiler_tests"

pass_count=0
fail_count=0
total_count=0

fail_names=()
fail_reasons=()

for driver_file in "$tests"/**/*_driver.c; do
    base_file="${driver_file%_driver.c}"
    base_name="${base_file##*/}"

    total_count=$((total_count + 1))

    echo ""
    echo "Test $base_name:"
    
    $jcc -I "$jcc_include" "$driver_file" "${base_file}.c" >/dev/null 2>&1
    
    if [[ $? -ne 0 ]]; then
        echo "$base_name: COMPILATION FAILED"
        fail_names+=("$base_name")
        fail_reasons+=("COMPILATION FAILED")
        fail_count=$((fail_count + 1))
        continue
    fi

    ./a.out
    
    if [[ $? -eq 0 ]]; then
        echo "$base_name passed"
        pass_count=$((pass_count + 1))
    else
        echo "$base_name: FAILED"
        fail_names+=("$base_name")
        fail_reasons+=("FAILED (wrong exit code)")
        fail_count=$((fail_count + 1))
    fi
done

echo ""
echo ""

echo -e "\033[1;32m$pass_count/$total_count tests passed\033[0m"
if [[ $fail_count -gt 0 ]]; then
    echo -e "\033[1;31mFailing tests:\033[0m"
    for i in "${!fail_names[@]}"; do
        echo -e "\033[1;31m${fail_names[$i]}: ${fail_reasons[$i]}\033[0m"
    done
fi
