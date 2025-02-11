# Copyright 2024 Thales DIS France SAS
# Licensed under the Solderpad Hardware Licence, Version 2.1 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# python script for Spyglass lint report
#
# Original Author: Asmaa Kassimi (asmaa.kassimi@external.thalesgroup.com) - Thales
#

import re
import sys
import subprocess
import report_builder as rb


def extract_info(summary_ref_results):
    pattern = re.compile(r"(WARNING|ERROR|INFO)\s+(\S+)\s+(\d+)\s+(.+)$")
    pattern2 = re.compile(r"^ +(.*)")
    info_list = []

    with open(summary_ref_results, "r", encoding="utf-8") as f:
        lines = f.readlines()

    for line in lines:
        match = pattern2.match(line)
        if match:
            (severity, rule_name, count, short_help) = info_list[-1]
            short_help += " " + match.group(1)
            info_list[-1] = (severity, rule_name, count, short_help)

        match = pattern.match(line)
        if match:
            severity = match.group(1)
            rule_name = match.group(2)
            count = match.group(3)
            short_help = match.group(4)

            info_list.append((severity, rule_name, count, short_help))

    return info_list


def compare_summaries(baseline_info, new_info):
    baseline_dict = {
        (severity, rule_name): (count, short_help)
        for severity, rule_name, count, short_help in baseline_info
    }
    new_dict = {
        (severity, rule_name): (count, short_help)
        for severity, rule_name, count, short_help in new_info
    }

    comparison_results = []

    for key, value in baseline_dict.items():
        if key not in new_dict:
            comparison_results.append((*key, *value, "PASS", "Deleted"))

    for key, value in new_dict.items():
        if key not in baseline_dict:
            comparison_results.append((*key, *value, "FAIL", "NEW"))

        else:
            if new_dict[key][0] == baseline_dict[key][0]:
                comparison_results.append((*key, *value, "PASS", "SAME"))
            else:
                message = (
                    f"Count changed from {baseline_dict[key][0]} to {new_dict[key][0]}"
                )
                comparison_results.append((*key, *value, "FAIL", message))

    severity_order = {"ERROR": 1, "WARNING": 2, "INFO": 3}
    comparison_results.sort(key=lambda x: severity_order[x[0]])

    return comparison_results


def report_spyglass_lint(comparison_results):
    metric = rb.TableStatusMetric("")
    metric.add_column("SEVERITY", "text")
    metric.add_column("RULE NAME", "text")
    metric.add_column("COUNT", "text")
    metric.add_column("SHORT HELP", "text")
    metric.add_column("DIFF", "text")

    for severity, rule_name, count, short_help, check, status in comparison_results:
        line = [severity, rule_name, count, short_help, status]
        if check == "PASS":
            metric.add_pass(*line)
        else:
            metric.add_fail(*line)

    report = rb.Report()
    report.add_metric(metric)
    report.dump()


def run_diff(ref_file, new_file):
    result = subprocess.run(
        [
            "diff",
            "-I",
            r"#\s+Report Name\s+:\s*[^#]*#\s+Report Created by\s*:\s*[^#]*#\s+Report Created on\s*:\s*[^#]*#\s+Working Directory\s*:\s*[^#]*",
            ref_file,
            new_file,
        ],
        capture_output=True,
        text=True,
    )
    if result.stdout:
        print("Found differences between reference and new summary")
        return False
    else:
        print("No differences found between reference and new summary")
        return True


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python script.py <summary_ref_results> <summary_file_path>")
        sys.exit(1)
    summary_ref_results = sys.argv[1]
    summary_rpt = sys.argv[2]

    no_diff = run_diff(summary_ref_results, summary_rpt)

    baseline_info = extract_info(summary_ref_results)
    new_info = extract_info(summary_rpt)
    comparison_results = compare_summaries(baseline_info, new_info)
    report_spyglass_lint(comparison_results)

    if not no_diff:
        print("Job failed due to differences in summaries")
        sys.exit(1)
