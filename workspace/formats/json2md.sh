#!/bin/bash
# Time-stamp: "2024-12-19 12:44:32 (ywatanabe)"
# File: ./Ninja/workspace/formats/json2md.sh

# Function to print help message
print_help() {
    cat << EOF
Usage:
    json2md <input.json>
    md2json <input.md>
Description:
    Convert between JSON and human-readable Markdown formats.
    Output filename is automatically determined by changing extension.
Arguments:
    input       Input file path
Options:
    -h, --help  Show this help message
EOF
    exit 0
}

# Function to determine output filename
get_output_filename() {
    local input=$1
    local cmd=$2

    case "$cmd" in
        json2md)
            echo "${input%.json}.md"
            ;;
        md2json)
            echo "${input%.md}.json"
            ;;
    esac
}

# json_to_md() {
#     local input=$1
#     local output=$2

#     {
#         local section=""
#         local max_key_width=12
#         local in_array=false
#         local array_key=""

#         # First pass for key width
#         while IFS= read -r line; do
#             if [[ $line =~ \"([^\"]+)\":\ *\"([^\"]+)\" ]]; then
#                 local key="${BASH_REMATCH[1]}"
#                 [[ ${#key} -gt $max_key_width ]] && max_key_width=${#key}
#             fi
#         done < "$input"

#         # Main processing
#         while IFS= read -r line; do
#             [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*[{}]$ ]] && continue

#             line="${line%,}"

#             if [[ $line =~ \"([^\"]+)\":\ *\{$ ]]; then
#                 section="${BASH_REMATCH[1]}"
#                 echo "## $section"
#                 echo

#             elif [[ $line =~ \"([^\"]+)\":\ *\[$ ]]; then
#                 in_array=true
#                 array_key="${BASH_REMATCH[1]}"

#             elif [[ $in_array == true ]]; then
#                 if [[ $line =~ \"([^\"]+)\" ]]; then
#                     printf "| %-${max_key_width}s | %s |\n" "$array_key" "${BASH_REMATCH[1]}"
#                 elif [[ $line =~ \] ]]; then
#                     in_array=false
#                 fi

#             elif [[ $line =~ \"([^\"]+)\":\ *\"([^\"]+)\" ]]; then
#                 printf "| %-${max_key_width}s | %s |\n" "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
#             fi

#         done < "$input"

#     } > "${output:-/dev/stdout}"
# }



json_to_md() {
    local input=$1
    local output=$2

    {
        # echo "# JSON Content"
        # echo

        local section=""
        local max_key_width=12
        local in_array=false
        local array_key=""

        # First pass for key width
        while IFS= read -r line; do
            if [[ $line =~ \"([^\"]+)\":\ *\"([^\"]+)\" ]]; then
                local key="${BASH_REMATCH[1]}"
                [[ ${#key} -gt $max_key_width ]] && max_key_width=${#key}
            fi
        done < "$input"

        # Main processing
        while IFS= read -r line; do
            [[ -z "${line//[[:space:]]/}" || "$line" =~ ^[[:space:]]*[{}]$ ]] && continue

            line="${line%,}"

            if [[ $line =~ \"([^\"]+)\":\ *\{$ ]]; then
                section="${BASH_REMATCH[1]}"
                echo "## $section"
                echo

            elif [[ $line =~ \"([^\"]+)\":\ *\[(.+)\]$ ]]; then
                key="${BASH_REMATCH[1]}"
                values=${BASH_REMATCH[2]}
                printf "| %-${max_key_width}s | [%s] |\n" "$key" "$values"

            elif [[ $line =~ \"([^\"]+)\":\ *\[$ ]]; then
                in_array=true
                array_key="${BASH_REMATCH[1]}"

            elif [[ $in_array == true ]]; then
                if [[ $line =~ \"([^\"]+)\" ]]; then
                    printf "| %-${max_key_width}s | %s |\n" "$array_key" "${BASH_REMATCH[1]}"
                elif [[ $line =~ \] ]]; then
                    in_array=false
                fi

            elif [[ $line =~ \"([^\"]+)\":\ *\"(.+)\"$ ]]; then
                value="${BASH_REMATCH[2]}"
                value="${value//\\\"/\"}"
                printf "| %-${max_key_width}s | %s |\n" "${BASH_REMATCH[1]}" "$value"
            fi

        done < "$input"

    } > "${output:-/dev/stdout}"
}


md_to_json() {
    local input=$1
    local output=$2
    local depth=0
    local in_section=""
    local first_item=true

    {
        echo "{"
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue

            if [[ "$line" =~ ^#[[:space:]](.*)$ ]]; then
                continue
            elif [[ "$line" =~ ^##[[:space:]]([^[:space:]].*)$ ]]; then
                [[ "$first_item" != true ]] && echo ","
                echo "    \"${BASH_REMATCH[1]}\": {"
                in_section="${BASH_REMATCH[1]}"
                first_item=false
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]([^:]+):[[:space:]]*(.*)$ ]]; then
                local key="${BASH_REMATCH[1]}"
                local value="${BASH_REMATCH[2]}"
                [[ -n "$value" ]] && echo "        \"$key\": $value,"
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(\[.*\])[[:space:]]*$ ]]; then
                echo "        ${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*-[[:space:]]*(.+)[[:space:]]*$ ]]; then
                echo "        ${BASH_REMATCH[1]},"
            fi
        done < "$input"
        echo "}"
    } > "${output:-/dev/stdout}"
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_help
                ;;
            *)
                break
                ;;
        esac
        shift
    done

    # Check for required arguments
    if [[ $# -lt 1 ]]; then
        echo "Error: Input file required" >&2
        print_help
    fi

    local cmd=$(basename "$0")
    # Remove .sh extension if present
    cmd=${cmd%.sh}

    # Process each input file
    for input in "$@"; do
        local output=$(get_output_filename "$input" "$cmd")

        # Check if input file exists
        if [[ ! -f "$input" ]]; then
            echo "Error: Input file not found: $input" >&2
            continue
        fi

        # Execute appropriate conversion based on command name
        case "$cmd" in
            json2md)
                json_to_md "$input" "$output"
                ;;
            md2json)
                md_to_json "$input" "$output"
                ;;
            *)
                echo "Error: Unknown command $cmd" >&2
                exit 1
                ;;
        esac

        echo ""
        echo "========================================"
        echo $input
        echo "----------------------------------------"
        cat $input
        echo "----------------------------------------"
        echo $output
        echo "----------------------------------------"
        cat $output
        echo "========================================"
        echo ""
    done
}

# Execute main function
main "$@"
