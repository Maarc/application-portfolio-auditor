#!/usr/bin/env bash
# Copyright 2019-2024 VMware, Inc.
# SPDX-License-Identifier: Apache-2.0

##############################################################################################################
# Extract key results from the reports generated by ...
#   "Microsoft Application Inspector" - https://github.com/microsoft/ApplicationInspector
##############################################################################################################

# ----- Please adjust

# ------ Do not modify
VERSION=${MAI_VERSION}
STEP=$(get_step)
SEPARATOR=","
APP_DIR_OUT="${REPORTS_DIR}/${STEP}__MAI"
export LOG_FILE="${APP_DIR_OUT}.log"
RESULT_FILE="${APP_DIR_OUT}/_results_extracted.csv"

function generate_csv() {
	echo "Applications${SEPARATOR}MAI unique tags" >"${RESULT_FILE}"
	while read -r FILE; do
		APP="$(basename "${FILE}")"
		log_extract_message "app '${APP}'"
		HTML_IN="${APP_DIR_OUT}/${APP}.html"
		TAGS="n/a"
		if [ -f "${HTML_IN}" ]; then
			TAGS="0"
			COUNT_TAGS=$(grep "Unique Tags Detected" "${HTML_IN}" | cut -d '(' -f 2 | cut -d')' -f 1)
			[ -n "${COUNT_TAGS}" ] && TAGS=${COUNT_TAGS}
		fi
		echo "${APP}${SEPARATOR}${TAGS}" >>"${RESULT_FILE}"
	done <"${REPORTS_DIR}/00__Weave/list__all_apps.txt"
	log_console_success "Results: ${RESULT_FILE}"
}

function main() {
	if [[ -d "${APP_DIR_OUT}" ]]; then
		generate_csv
	else
		LOG_FILE=/dev/null
		log_console_error "MAIN result directory does not exist: ${APP_DIR_OUT}"
		return
	fi
}

main
