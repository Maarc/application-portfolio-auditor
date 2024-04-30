#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Extract key results from the report files generated by ...
#   "Open Web Application Security Project (OWASP) Dependency-Check" - https://www.owasp.org/index.php/OWASP_Dependency_Check
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${OWASP_DC_VERSION}
STEP=$(get_step)
SEPARATOR=","
APP_DIR_OUT="${REPORTS_DIR}/${STEP}__OWASP_DC"
RESULT_FILE="${APP_DIR_OUT}/_results_extracted.csv"
RESULT_FILE_FULL="${APP_DIR_OUT}/_results_extracted_full.csv"
export LOG_FILE="${APP_DIR_OUT}.log"

function generate_csv() {

	echo "Applications${SEPARATOR}OWASP vulns" >"${RESULT_FILE}"
	echo "Applications${SEPARATOR}OWASP Low vulns${SEPARATOR}OWASP Medium vulns${SEPARATOR}OWASP High vulns${SEPARATOR}OWASP Critical vulns${SEPARATOR}OWASP Total vuln libs" >"${RESULT_FILE_FULL}"

	while read -r FILE; do
		APP="$(basename "${FILE}")"
		log_extract_message "app '${APP}'"

		DCR_JSON_IN="${APP_DIR_OUT}/${APP}_dc_report.json"

		if [ -f "${DCR_JSON_IN}" ]; then

			# shellcheck disable=SC2126
			COUNT_VULN_DEPENDENCIES=$(jq ".dependencies[].vulnerabilities | length" "${DCR_JSON_IN}" | grep -v '^0$' | wc -l | tr -d ' ')

			declare -i COUNT_LOW=0
			declare -i COUNT_MEDIUM=0
			declare -i COUNT_HIGH=0
			declare -i COUNT_CRITICAL=0

			# Extract the CSVV2 and CVSS3 scores
			while read -r SCORES; do
				# Max of CVSS2 and CVSS3
				CVSS=$(echo "${SCORES}" | awk -F ' ' '{ print ($1 >= $2) ? $1 : $2 }')
				if [[ $(awk -v cvss="${CVSS}" 'BEGIN { print (cvss >= 9.0) ? "T" : "F" }') == "T" ]]; then
					COUNT_CRITICAL=$((COUNT_CRITICAL + 1))
				elif [[ $(awk -v cvss="${CVSS}" 'BEGIN { print (cvss >= 7.0) ? "T" : "F" }') == "T" ]]; then
					COUNT_HIGH=$((COUNT_HIGH + 1))
				elif [[ $(awk -v cvss="${CVSS}" 'BEGIN { print (cvss >= 4.0) ? "T" : "F" }') == "T" ]]; then
					COUNT_MEDIUM=$((COUNT_MEDIUM + 1))
				else
					COUNT_LOW=$((COUNT_LOW + 1))
				fi
			done < <(jq '.dependencies[]?.vulnerabilities[]? | "\(.cvssv3.baseScore) \(.cvssv2.score)"' "${DCR_JSON_IN}" | tr -d '"' | sed s/null/0/g)

			COUT_TOTAL=$((COUNT_LOW + COUNT_MEDIUM + COUNT_HIGH + COUNT_CRITICAL))

			echo "${APP}${SEPARATOR}${COUT_TOTAL}" >>"${RESULT_FILE}"
			echo "${APP}${SEPARATOR}${COUNT_LOW}${SEPARATOR}${COUNT_MEDIUM}${SEPARATOR}${COUNT_HIGH}${SEPARATOR}${COUNT_CRITICAL}${SEPARATOR}${COUNT_VULN_DEPENDENCIES}" >>"${RESULT_FILE_FULL}"
		else
			echo "${APP}${SEPARATOR}n/a" >>"${RESULT_FILE}"
			echo "${APP}${SEPARATOR}n/a${SEPARATOR}n/a${SEPARATOR}n/a${SEPARATOR}n/a${SEPARATOR}n/a" >>"${RESULT_FILE_FULL}"
		fi
	done <"${REPORTS_DIR}/00__Weave/list__all_apps.txt"

	log_console_success "Results: ${RESULT_FILE}"
}

function main() {
	if [[ -d "${APP_DIR_OUT}" ]]; then
		generate_csv
	else
		LOG_FILE=/dev/null
		log_console_error "OWASP result directory does not exist: ${APP_DIR_OUT}"
	fi
}

main
