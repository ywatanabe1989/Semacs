#!/bin/bash
# Time-stamp: "2024-12-17 07:11:25 (ywatanabe)"
# File: ./Ninja/src/apptainer_builders/working_directory_setup_shared_dir.sh

# # My feedback on this script


# Helper function
ensure_sdir() {
    local spath="$1"
    mkdir -p "$(dirname "$spath")" > /dev/null
}

# Template functions
create_agent_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/agents/templates/agent-template.md"
    ensure_sdir "$spath"

    echo "---
title: \"[Agent Name] Template\"
available tags: [agent-template, role, available-tools, expertise]
---

# Agent Template: [Agent Name]

## **Role**

- **Primary Role:** [Describe the primary role of the agent]
- **Responsibilities:**
- [Responsibility 1]
- [Responsibility 2]

## **Available Tools**

- [Tool 1](../tools/tool-001.md)
- [Tool 2](../tools/tool-002.md)

## **Expertise**

- [Area of Expertise 1]
- [Area of Expertise 2]

## **Communication Protocols**

- **Preferred Method:** [e.g., Not allowed, Direct Messages, Forums]

## **Authorities**

## **Additional Notes**

[Include any additional information relevant to the agent.]" > "$spath"
}
# create_agent_template /workspace

md2json_agent_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"

    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi

    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local role=$(sed -n '/## \*\*Role\*\*$/,/## \*\*Available Tools\*\*/p' "$md_file" | sed '1d;$d' | grep -v "Responsibilities:" | sed 's/- //g' | tr '\n' ' ')
    local responsibilities=$(sed -n '/## \*\*Role\*\*$/,/## \*\*Available Tools\*\*/p' "$md_file" | sed '1d;$d' | grep "Responsibilities:" | sed 's/- //g; s/Responsibilities://' | tr '\n' ' ')
    local tools=$(sed -n '/## \*\*Available Tools\*\*$/,/## \*\*Expertise\*\*/p' "$md_file" | sed '1d;$d' | sed 's/- //g' | tr '\n' ' ')
    local expertise=$(sed -n '/## \*\*Expertise\*\*$/,/## \*\*Communication Protocols\*\*/p' "$md_file" | sed '1d;$d' | sed 's/- //g' | tr '\n' ' ')
    local communication=$(sed -n '/## \*\*Communication Protocols\*\*$/,/## \*\*Authorities\*\*/p' "$md_file" | sed '1d;$d' | sed 's/- **Preferred Method:** //g' | tr '\n' ' ')
    local authorities=$(sed -n '/## \*\*Authorities\*\*$/,/## \*\*Additional Notes\*\*/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local notes=$(sed -n '/## \*\*Additional Notes\*\*$/,$p' "$md_file" | sed '1d' | tr '\n' ' ')

    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"role\": \"$role\",
    \"responsibilities\": [$(echo "$responsibilities" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"available_tools\": [$(echo "$tools" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"expertise\": [$(echo "$expertise" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"communication_protocols\": \"$communication\",
     \"authorities\": \"$authorities\",
    \"additional_notes\": \"$notes\"

  }" > "$json_file"
}


json2md_agent_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"

    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi

    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local role=$(jq -r ".role" "$json_file")
    local responsibilities=$(jq -r ".responsibilities[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local tools=$(jq -r ".available_tools[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local expertise=$(jq -r ".expertise[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local communication=$(jq -r ".communication_protocols" "$json_file")
    local authorities=$(jq -r ".authorities" "$json_file")
    local notes=$(jq -r ".additional_notes" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# Agent Template: $title

## **Role**

- **Primary Role:** $role
- **Responsibilities:**
- $responsibilities

## **Available Tools**

- $tools

## **Expertise**

- $expertise

## **Communication Protocols**

- **Preferred Method:** $communication

## **Authorities**

$authorities

## **Additional Notes**

$notes
" > "$md_file"
}


verify_md_agent_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi

    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi

    local role=$(sed -n '/## \*\*Role\*\*$/,/## \*\*Available Tools\*\*/p' "$md_file")
    if [ -z "$role" ]; then
        echo "Error: role not found in $md_file" >&2
        return 1
    fi
    local tools=$(sed -n '/## \*\*Available Tools\*\*$/,/## \*\*Expertise\*\*/p' "$md_file")
    if [ -z "$tools" ]; then
        echo "Error: available tools not found in $md_file" >&2
        return 1
    fi
    local expertise=$(sed -n '/## \*\*Expertise\*\*$/,/## \*\*Communication Protocols\*\*/p' "$md_file")
    if [ -z "$expertise" ]; then
        echo "Error: expertise not found in $md_file" >&2
        return 1
    fi
    local communication=$(sed -n '/## \*\*Communication Protocols\*\*$/,/## \*\*Authorities\*\*/p' "$md_file")
    if [ -z "$communication" ]; then
        echo "Error: communication protocols not found in $md_file" >&2
        return 1
    fi
    local authorities=$(sed -n '/## \*\*Authorities\*\*$/,/## \*\*Additional Notes\*\*/p' "$md_file")
    if [ -z "$authorities" ]; then
        echo "Error: authorities not found in $md_file" >&2
        return 1
    fi
    local notes=$(sed -n '/## \*\*Additional Notes\*\*$/,$p' "$md_file")
    if [ -z "$notes" ]; then
        echo "Error: notes not found in $md_file" >&2
        return 1
    fi

    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_agent_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local role=$(jq -e ".role" "$json_file")
    if [ -z "$role" ]; then
        echo "Error: role not found in $json_file" >&2
        return 1
    fi
    local responsibilities=$(jq -e ".responsibilities" "$json_file")
    if [ -z "$responsibilities" ]; then
        echo "Error: responsibilities not found in $json_file" >&2
        return 1
    fi
    local tools=$(jq -e ".available_tools" "$json_file")
    if [ -z "$tools" ]; then
        echo "Error: available_tools not found in $json_file" >&2
        return 1
    fi
    local expertise=$(jq -e ".expertise" "$json_file")
    if [ -z "$expertise" ]; then
        echo "Error: expertise not found in $json_file" >&2
        return 1
    fi
    local communication=$(jq -e ".communication_protocols" "$json_file")
    if [ -z "$communication" ]; then
        echo "Error: communication_protocols not found in $json_file" >&2
        return 1
    fi
    local authorities=$(jq -e ".authorities" "$json_file")
    if [ -z "$authorities" ]; then
        echo "Error: authorities not found in $json_file" >&2
        return 1
    fi
    local notes=$(jq -e ".additional_notes" "$json_file")
    if [ -z "$notes" ]; then
        echo "Error: additional_notes not found in $json_file" >&2
        return 1
    fi

    echo "JSON file $json_file is valid"
    return 0
}


create_agent_config() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/agents/configs/.agent-config.json"
    ensure_sdir "$spath"

    echo "{
    \"agent_id\": \"agent-001\",
    \"name\": \"Example Agent\",
    \"model\": \"gpt-4\",
    \"temperature\": 0.7,
    \"max_tokens\": 2000
    }" > "$spath"
}
# create_agent_config /workspace

md2json_agent_config() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"

    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi

    local agent_id=$(grep "^agent_id: " "$md_file" | sed 's/^agent_id: "//;s/"$//')
    local name=$(grep "^name: " "$md_file" | sed 's/^name: "//;s/"$//')
    local model=$(grep "^model: " "$md_file" | sed 's/^model: "//;s/"$//')
    local temperature=$(grep "^temperature: " "$md_file" | sed 's/^temperature: "//;s/"$//')
    local max_tokens=$(grep "^max_tokens: " "$md_file" | sed 's/^max_tokens: "//;s/"$//')

    echo "{
    \"agent_id\": \"$agent_id\",
    \"name\": \"$name\",
    \"model\": \"$model\",
    \"temperature\": \"$temperature\",
    \"max_tokens\": \"$max_tokens\"
    }" > "$json_file"
}

json2md_agent_config() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"

    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi

    local agent_id=$(jq -r ".agent_id" "$json_file")
    local name=$(jq -r ".name" "$json_file")
    local model=$(jq -r ".model" "$json_file")
    local temperature=$(jq -r ".temperature" "$json_file")
    local max_tokens=$(jq -r ".max_tokens" "$json_file")

    echo "agent_id: \"$agent_id\"
name: \"$name\"
model: \"$model\"
temperature: \"$temperature\"
max_tokens: \"$max_tokens\"
" > "$md_file"
}

verify_json_agent_config() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local agent_id=$(jq -e ".agent_id" "$json_file")
    if [ -z "$agent_id" ]; then
        echo "Error: agent_id not found in $json_file" >&2
        return 1
    fi
    local name=$(jq -e ".name" "$json_file")
    if [ -z "$name" ]; then
        echo "Error: name not found in $json_file" >&2
        return 1
    fi
    local model=$(jq -e ".model" "$json_file")
    if [ -z "$model" ]; then
        echo "Error: model not found in $json_file" >&2
        return 1
    fi
    local temperature=$(jq -e ".temperature" "$json_file")
    if [ -z "$temperature" ]; then
        echo "Error: temperature not found in $json_file" >&2
        return 1
    fi
    local max_tokens=$(jq -e ".max_tokens" "$json_file")
    if [ -z "$max_tokens" ]; then
        echo "Error: max_tokens not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}
verify_md_agent_config() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local agent_id=$(grep "^agent_id: " "$md_file")
    if [ -z "$agent_id" ]; then
        echo "Error: agent_id not found in $md_file" >&2
        return 1
    fi
    local name=$(grep "^name: " "$md_file")
    if [ -z "$name" ]; then
        echo "Error: name not found in $md_file" >&2
        return 1
    fi
    local model=$(grep "^model: " "$md_file")
    if [ -z "$model" ]; then
        echo "Error: model not found in $md_file" >&2
        return 1
    fi
    local temperature=$(grep "^temperature: " "$md_file")
    if [ -z "$temperature" ]; then
        echo "Error: temperature not found in $md_file" >&2
        return 1
    fi
    local max_tokens=$(grep "^max_tokens: " "$md_file")
    if [ -z "$max_tokens" ]; then
        echo "Error: max_tokens not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}



create_tool_md_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/tools/tool-001/tool.md"
    ensure_sdir "$spath"

    echo "---
title: \"Example Tool\"
available tags: [tool name, description, elisp command, examples]
---

# Tool: Example Tool

## **Description**

This is an example tool.

## **Usage**

## **Elisp Command**
\`\`\`emacs-lisp
(progn
  (command1 arg1 arg2)
  (command2 arg1 arg2)
  ...)
\`\`\`

## **Examples**

- **Example 1:**

\`\`\`emacs-lisp
(progn
(setq default-directory \"/workspace/\")
(delete-other-windows)
(split-window-right)
(let* ((timestamp (format-time-string \"%Y%m%d-%H%M%S\"))
(script-filename (expand-file-name (format \"plot-%s.py\" timestamp) default-directory))
(image-filename (expand-file-name (format \"plot-%s.png\" timestamp)))
(py-code \"
import matplotlib.pyplot as plt
import numpy as np

np.random.seed(19680801)

dt = 0.01
t = np.arange(0, 30, dt)
nse1 = np.random.randn(len(t))
nse2 = np.random.randn(len(t))

s1 = np.sin(2 * np.pi * 10 * t) + nse1
s2 = np.sin(2 * np.pi * 10 * t) + nse2

fig, axs = plt.subplots(2, 1, layout='constrained')
axs[0].plot(t, s1, t, s2)
axs[0].set_xlim(0, 2)
axs[0].set_xlabel('Time (s)')
axs[0].set_ylabel('s1 and s2')
axs[0].grid(True)

cxy, f = axs[1].cohere(s1, s2, 256, 1. / dt)
axs[1].set_ylabel('Coherence')

plt.savefig('image-file')
\"))
    (with-temp-buffer
(insert (replace-regexp-in-string \"image-file\" image-filename py-code))
(write-region (point-min) (point-max) script-filename)
(shell-command (format \"bash -c 'source /workspace/.env/bin/activate && python3 %s'\" script-filename)))
    (find-file script-filename)
    (sleep-for 3)
    (other-window 1)
    (find-file (expand-file-name image-filename default-directory))
    (sleep-for 3)))
\"))" > "$spath"
}
# create_tool_md_template /workspace

md2json_tool_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local description=$(sed -n '/## \*\*Description\*\*$/,/## \*\*Usage\*\*/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local elisp_command=$(sed -n '/## \*\*Elisp Command\*\*$/,/## \*\*Examples\*\*/p' "$md_file" | sed '1d;$d' | sed 's/```emacs-lisp//;s/```//' | tr '\n' ' ')
    local examples=$(sed -n '/## \*\*Examples\*\*$/,$p' "$md_file" | sed '1d' | sed 's/```emacs-lisp//;s/```//' | tr '\n' ' ')

    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"description\": \"$description\",
    \"elisp_command\": \"$elisp_command\",
    \"examples\": \"$examples\"

  }" > "$json_file"
}

json2md_tool_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"

    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi

    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local description=$(jq -r ".description" "$json_file")
    local elisp_command=$(jq -r ".elisp_command" "$json_file")
    local examples=$(jq -r ".examples" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# Tool: $title

## **Description**

$description

## **Usage**

## **Elisp Command**
\`\`\`emacs-lisp
$elisp_command
\`\`\`

## **Examples**

$examples
" > "$md_file"
}

verify_md_tool_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local description=$(sed -n '/## \*\*Description\*\*$/,/## \*\*Usage\*\*/p' "$md_file")
    if [ -z "$description" ]; then
        echo "Error: description not found in $md_file" >&2
        return 1
    fi
    local elisp_command=$(sed -n '/## \*\*Elisp Command\*\*$/,/## \*\*Examples\*\*/p' "$md_file")
    if [ -z "$elisp_command" ]; then
        echo "Error: elisp command not found in $md_file" >&2
        return 1
    fi
    local examples=$(sed -n '/## \*\*Examples\*\*$/,$p' "$md_file")
    if [ -z "$examples" ]; then
        echo "Error: examples not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_tool_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local description=$(jq -e ".description" "$json_file")
    if [ -z "$description" ]; then
        echo "Error: description not found in $json_file" >&2
        return 1
    fi
    local elisp_command=$(jq -e ".elisp_command" "$json_file")
    if [ -z "$elisp_command" ]; then
        echo "Error: elisp_command not found in $json_file" >&2
        return 1
    fi
    local examples=$(jq -e ".examples" "$json_file")
    if [ -z "$examples" ]; then
        echo "Error: examples not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_tool_json_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/tools/.tool-001.json"
    ensure_sdir "$spath"
    echo "{
    \"tool_id\": \"tool-001\",
    \"tool_name\": \"Example Tool\",
    \"description\": \"This is an example tool.\",
    \"elisp_command\": \"(progn (command1 arg1 arg2))\",
     \"input\": {
      \"type\": \"object\",
      \"properties\": {
          \"arg1\": { \"type\": \"string\", \"description\": \"Argument 1\" },
          \"arg2\": { \"type\": \"integer\", \"description\": \"Argument 2\" }
        },
      \"required\": [\"arg1\",\"arg2\"]
    },
    \"output\": {
        \"type\": \"object\",
        \"properties\": {
            \"result\": {\"type\": \"string\", \"description\": \"The result of the tool\"},
          \"status\": {\"type\": \"string\", \"description\": \"Status of the tool's execution\"}
        },
        \"required\": [\"result\", \"status\"]
    }
}" > "$spath"
}

create_tool_schema_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/tools/.tool-schema.json"
    ensure_sdir "$spath"
    echo "{
      \"type\": \"object\",
      \"properties\": {
          \"tool_id\": { \"type\": \"string\" },
          \"tool_name\": { \"type\": \"string\" },
          \"description\": { \"type\": \"string\" },
          \"elisp_command\": { \"type\": \"string\" },
          \"input\": {
            \"type\": \"object\",
            \"properties\": {
              \"arg1\": { \"type\": \"string\" },
              \"arg2\": { \"type\": \"integer\" }
            },
            \"required\": [\"arg1\", \"arg2\"]
          },
           \"output\": {
            \"type\": \"object\",
            \"properties\": {
              \"result\": { \"type\": \"string\" },
              \"status\": { \"type\": \"string\" }
             },
            \"required\": [\"result\", \"status\"]
          }
        },
      \"required\": [\"tool_id\", \"tool_name\", \"description\", \"elisp_command\", \"input\", \"output\"]
    }" > "$spath"
}

create_prompt_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/prompts/prompt-template.md"
    ensure_sdir "$spath"
    echo "---
title: \"[Prompt Title]\"
available tags: [prompt-template, background, requests, tools, where, when, how, expected-output, output-format]
---

# [Prompt Title]

## Background

[Explain the purpose of the prompt.]

## Requests

[Describe what is being requested.]

## Tools (optional)

[Specify any options or selections relevant to the prompt.]

## Data (optional)

## Queue (optional)

## **Expected Output**

[Detail what the expected result should be.]

## **Output Format**

[Specify the desired format of the output, e.g., plain text, JSON, Markdown.]

## **Additional Context**

[Include any other relevant information.]" > "$spath"
}

md2json_prompt_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local background=$(sed -n '/## Background$/,/## Requests/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local requests=$(sed -n '/## Requests$/,/## Tools \(optional\)/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local tools=$(sed -n '/## Tools \(optional\)$/,/## Data \(optional\)/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local data=$(sed -n '/## Data \(optional\)$/,/## Queue \(optional\)/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local queue=$(sed -n '/## Queue \(optional\)$/,/## \*\*Expected Output\*\*/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local expected_output=$(sed -n '/## \*\*Expected Output\*\*$/,/## \*\*Output Format\*\*/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local output_format=$(sed -n '/## \*\*Output Format\*\*$/,/## \*\*Additional Context\*\*/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local additional_context=$(sed -n '/## \*\*Additional Context\*\*$/,$p' "$md_file" | sed '1d' | tr '\n' ' ')

    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"background\": \"$background\",
    \"requests\": \"$requests\",
    \"tools\": \"$tools\",
    \"data\": \"$data\",
    \"queue\": \"$queue\",
     \"expected_output\": \"$expected_output\",
    \"output_format\": \"$output_format\",
    \"additional_context\": \"$additional_context\"
  }" > "$json_file"
}


json2md_prompt_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local background=$(jq -r ".background" "$json_file")
    local requests=$(jq -r ".requests" "$json_file")
    local tools=$(jq -r ".tools" "$json_file")
    local data=$(jq -r ".data" "$json_file")
    local queue=$(jq -r ".queue" "$json_file")
    local expected_output=$(jq -r ".expected_output" "$json_file")
    local output_format=$(jq -r ".output_format" "$json_file")
    local additional_context=$(jq -r ".additional_context" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# $title

## Background

$background

## Requests

$requests

## Tools (optional)

$tools

## Data (optional)

$data

## Queue (optional)

$queue

## **Expected Output**

$expected_output

## **Output Format**

$output_format

## **Additional Context**

$additional_context
" > "$md_file"
}

verify_md_prompt_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local background=$(sed -n '/## Background$/,/## Requests/p' "$md_file")
    if [ -z "$background" ]; then
        echo "Error: background not found in $md_file" >&2
        return 1
    fi
    local requests=$(sed -n '/## Requests$/,/## Tools \(optional\)/p' "$md_file")
    if [ -z "$requests" ]; then
        echo "Error: requests not found in $md_file" >&2
        return 1
    fi
    local tools=$(sed -n '/## Tools \(optional\)$/,/## Data \(optional\)/p' "$md_file")
    if [ -z "$tools" ]; then
        echo "Error: tools not found in $md_file" >&2
        return 1
    fi
    local data=$(sed -n '/## Data \(optional\)$/,/## Queue \(optional\)/p' "$md_file")
    if [ -z "$data" ]; then
        echo "Error: data not found in $md_file" >&2
        return 1
    fi
    local queue=$(sed -n '/## Queue \(optional\)$/,/## \*\*Expected Output\*\*/p' "$md_file")
    if [ -z "$queue" ]; then
        echo "Error: queue not found in $md_file" >&2
        return 1
    fi
    local expected_output=$(sed -n '/## \*\*Expected Output\*\*$/,/## \*\*Output Format\*\*/p' "$md_file")
    if [ -z "$expected_output" ]; then
        echo "Error: expected_output not found in $md_file" >&2
        return 1
    fi
    local output_format=$(sed -n '/## \*\*Output Format\*\*$/,/## \*\*Additional Context\*\*/p' "$md_file")
    if [ -z "$output_format" ]; then
        echo "Error: output_format not found in $md_file" >&2
        return 1
    fi
    local additional_context=$(sed -n '/## \*\*Additional Context\*\*$/,$p' "$md_file")
    if [ -z "$additional_context" ]; then
        echo "Error: additional_context not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_prompt_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local background=$(jq -e ".background" "$json_file")
    if [ -z "$background" ]; then
        echo "Error: background not found in $json_file" >&2
        return 1
    fi
    local requests=$(jq -e ".requests" "$json_file")
    if [ -z "$requests" ]; then
        echo "Error: requests not found in $json_file" >&2
        return 1
    fi
    local tools=$(jq -e ".tools" "$json_file")
    if [ -z "$tools" ]; then
        echo "Error: tools not found in $json_file" >&2
        return 1
    fi
    local data=$(jq -e ".data" "$json_file")
    if [ -z "$data" ]; then
        echo "Error: data not found in $json_file" >&2
        return 1
    fi
    local queue=$(jq -e ".queue" "$json_file")
    if [ -z "$queue" ]; then
        echo "Error: queue not found in $json_file" >&2
        return 1
    fi
    local expected_output=$(jq -e ".expected_output" "$json_file")
    if [ -z "$expected_output" ]; then
        echo "Error: expected_output not found in $json_file" >&2
        return 1
    fi
    local output_format=$(jq -e ".output_format" "$json_file")
    if [ -z "$output_format" ]; then
        echo "Error: output_format not found in $json_file" >&2
        return 1
    fi
    local additional_context=$(jq -e ".additional_context" "$json_file")
    if [ -z "$additional_context" ]; then
        echo "Error: additional_context not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_prompt_json_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/prompts/.prompt-template.json"
    ensure_sdir "$spath"
    echo "{
  \"prompt_id\": \"prompt-001\",
  \"description\": \"This is a prompt description.\",
   \"input\": {
    \"type\": \"object\",
    \"properties\": {
      \"arg1\": { \"type\": \"string\", \"description\": \"Argument 1\" },
      \"arg2\": { \"type\": \"integer\", \"description\": \"Argument 2\" }
        },
    \"required\": [\"arg1\", \"arg2\"]
    },
   \"output\": {
      \"type\": \"object\",
      \"properties\": {
          \"result\": { \"type\": \"string\", \"description\": \"The result of the prompt\" }
      },
      \"required\": [\"result\"]
  }
}" > "$spath"
}


create_knowledge_base_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/knowledge_base/.knowledge.json"
    local spath_md="$workspace_dir/shared/knowledge_base/.knowledge.md"
    ensure_sdir "$spath"
    ensure_sdir "$spath_md"
    echo "{
  \"knowledge_base_id\": \"knowledge-base-001\",
  \"description\": \"This is a knowledge base.\",
  \"entries\": [
    {
      \"entry_id\": \"entry-001\",
      \"content\": \"This is a test knowledge entry.\",
       \"tags\": [\"knowledge\", \"test\"]
    }
    ]
}" > "$spath"
    echo "---
title: \"Knowledge Base\"
available tags: [knowledge, test]
---

# Knowledge Base

This is a test knowledge entry.
" > "$spath_md"
}

md2json_knowledge_base_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"

    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi

    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Knowledge Base$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')

    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
  }" > "$json_file"
}

json2md_knowledge_base_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# Knowledge Base

$content
" > "$md_file"
}
verify_md_knowledge_base_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Knowledge Base$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_knowledge_base_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_system_log_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/system/logs/system.log"
    ensure_sdir "$spath"
    echo "System log started $(date)" > "$spath"
}

create_data_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/data/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Data README\"
available tags: [data description, data source, data quality, data processing]
---

# Data README

This is a test data README.
" > "$spath"
}

md2json_data_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Data README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_data_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Data README

$content
" > "$md_file"
}

verify_md_data_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Data README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_data_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}



create_docs_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/docs/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Docs README\"
available tags: [documentation, instructions]
---

# Docs README

This is a test documentation README.
" > "$spath"
}

md2json_docs_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Docs README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_docs_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Docs README

$content
" > "$md_file"
}

verify_md_docs_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Docs README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_docs_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_report_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/outputs/report-001/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Report README\"
available tags: [report title, report description, data analysis, results, plots, interpretation]
---

# Report README

This is a test report README.
" > "$spath"
}

md2json_report_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Report README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_report_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Report README

$content
" > "$md_file"
}

verify_md_report_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Report README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_report_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}



create_outputs_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/outputs/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Outputs README\"
available tags: [outputs description, data analysis, results, plots, interpretation]
---

# Outputs README

This is a test outputs README.
" > "$spath"
}

md2json_outputs_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Outputs README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_outputs_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Outputs README

$content
" > "$md_file"
}


verify_md_outputs_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Outputs README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_outputs_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}
create_tool_json_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/tools/tool-001/tool.json"
    ensure_sdir "$spath"
    echo "{
  \"tool_id\": \"tool-001\",
  \"description\": \"This is a tool description.\",
   \"input\": {
    \"type\": \"object\",
    \"properties\": {
      \"arg1\": { \"type\": \"string\", \"description\": \"Argument 1\" },
      \"arg2\": { \"type\": \"integer\", \"description\": \"Argument 2\" }
    },
    \"required\": [\"arg1\", \"arg2\"]
  },
   \"output\": {
    \"type\": \"object\",
    \"properties\": {
      \"result\": { \"type\": \"string\", \"description\": \"The result of the tool\" }
        },
        \"required\": [\"result\"]
    }
}" > "$spath"
}

json2md_prompt_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local background=$(jq -r ".background" "$json_file")
    local requests=$(jq -r ".requests" "$json_file")
    local tools=$(jq -r ".tools" "$json_file")
    local data=$(jq -r ".data" "$json_file")
    local queue=$(jq -r ".queue" "$json_file")
    local expected_output=$(jq -r ".expected_output" "$json_file")
    local output_format=$(jq -r ".output_format" "$json_file")
    local additional_context=$(jq -r ".additional_context" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# $title

## Background

$background

## Requests

$requests

## Tools (optional)

$tools

## Data (optional)

$data

## Queue (optional)

$queue

## **Expected Output**

$expected_output

## **Output Format**

$output_format

## **Additional Context**

$additional_context
" > "$md_file"
}

verify_md_prompt_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local background=$(sed -n '/## Background$/,/## Requests/p' "$md_file")
    if [ -z "$background" ]; then
        echo "Error: background not found in $md_file" >&2
        return 1
    fi
    local requests=$(sed -n '/## Requests$/,/## Tools \(optional\)/p' "$md_file")
    if [ -z "$requests" ]; then
        echo "Error: requests not found in $md_file" >&2
        return 1
    fi
    local tools=$(sed -n '/## Tools \(optional\)$/,/## Data \(optional\)/p' "$md_file")
    if [ -z "$tools" ]; then
        echo "Error: tools not found in $md_file" >&2
        return 1
    fi
    local data=$(sed -n '/## Data \(optional\)$/,/## Queue \(optional\)/p' "$md_file")
    if [ -z "$data" ]; then
        echo "Error: data not found in $md_file" >&2
        return 1
    fi
    local queue=$(sed -n '/## Queue \(optional\)$/,/## \*\*Expected Output\*\*/p' "$md_file")
    if [ -z "$queue" ]; then
        echo "Error: queue not found in $md_file" >&2
        return 1
    fi
    local expected_output=$(sed -n '/## \*\*Expected Output\*\*$/,/## \*\*Output Format\*\*/p' "$md_file")
    if [ -z "$expected_output" ]; then
        echo "Error: expected_output not found in $md_file" >&2
        return 1
    fi
    local output_format=$(sed -n '/## \*\*Output Format\*\*$/,/## \*\*Additional Context\*\*/p' "$md_file")
    if [ -z "$output_format" ]; then
        echo "Error: output_format not found in $md_file" >&2
        return 1
    fi
    local additional_context=$(sed -n '/## \*\*Additional Context\*\*$/,$p' "$md_file")
    if [ -z "$additional_context" ]; then
        echo "Error: additional_context not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_prompt_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local background=$(jq -e ".background" "$json_file")
    if [ -z "$background" ]; then
        echo "Error: background not found in $json_file" >&2
        return 1
    fi
    local requests=$(jq -e ".requests" "$json_file")
    if [ -z "$requests" ]; then
        echo "Error: requests not found in $json_file" >&2
        return 1
    fi
    local tools=$(jq -e ".tools" "$json_file")
    if [ -z "$tools" ]; then
        echo "Error: tools not found in $json_file" >&2
        return 1
    fi
    local data=$(jq -e ".data" "$json_file")
    if [ -z "$data" ]; then
        echo "Error: data not found in $json_file" >&2
        return 1
    fi
    local queue=$(jq -e ".queue" "$json_file")
    if [ -z "$queue" ]; then
        echo "Error: queue not found in $json_file" >&2
        return 1
    fi
    local expected_output=$(jq -e ".expected_output" "$json_file")
    if [ -z "$expected_output" ]; then
        echo "Error: expected_output not found in $json_file" >&2
        return 1
    fi
    local output_format=$(jq -e ".output_format" "$json_file")
    if [ -z "$output_format" ]; then
        echo "Error: output_format not found in $json_file" >&2
        return 1
    fi
    local additional_context=$(jq -e ".additional_context" "$json_file")
    if [ -z "$additional_context" ]; then
        echo "Error: additional_context not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_prompt_json_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/prompts/.prompt-template.json"
    ensure_sdir "$spath"
    echo "{
  \"prompt_id\": \"prompt-001\",
  \"description\": \"This is a prompt description.\",
   \"input\": {
    \"type\": \"object\",
    \"properties\": {
      \"arg1\": { \"type\": \"string\", \"description\": \"Argument 1\" },
      \"arg2\": { \"type\": \"integer\", \"description\": \"Argument 2\" }
        },
    \"required\": [\"arg1\", \"arg2\"]
    },
   \"output\": {
      \"type\": \"object\",
      \"properties\": {
          \"result\": { \"type\": \"string\", \"description\": \"The result of the prompt\" }
      },
      \"required\": [\"result\"]
  }
}" > "$spath"
}


create_knowledge_base_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/knowledge_base/.knowledge.json"
    local spath_md="$workspace_dir/shared/knowledge_base/.knowledge.md"
    ensure_sdir "$spath"
    ensure_sdir "$spath_md"
    echo "{
  \"knowledge_base_id\": \"knowledge-base-001\",
  \"description\": \"This is a knowledge base.\",
  \"entries\": [
    {
      \"entry_id\": \"entry-001\",
      \"content\": \"This is a test knowledge entry.\",
       \"tags\": [\"knowledge\", \"test\"]
    }
    ]
}" > "$spath"
    echo "---
title: \"Knowledge Base\"
available tags: [knowledge, test]
---

# Knowledge Base

This is a test knowledge entry.
" > "$spath_md"
}

md2json_knowledge_base_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"

    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi

    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Knowledge Base$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')

    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
  }" > "$json_file"
}

json2md_knowledge_base_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# Knowledge Base

$content
" > "$md_file"
}
verify_md_knowledge_base_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Knowledge Base$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_knowledge_base_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_system_log_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/shared/system/logs/system.log"
    ensure_sdir "$spath"
    echo "System log started $(date)" > "$spath"
}

create_data_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/data/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Data README\"
available tags: [data description, data source, data quality, data processing]
---

# Data README

This is a test data README.
" > "$spath"
}

md2json_data_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Data README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_data_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Data README

$content
" > "$md_file"
}

verify_md_data_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Data README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_data_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}



create_docs_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/docs/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Docs README\"
available tags: [documentation, instructions]
---

# Docs README

This is a test documentation README.
" > "$spath"
}

md2json_docs_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Docs README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_docs_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Docs README

$content
" > "$md_file"
}

verify_md_docs_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Docs README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_docs_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_report_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/outputs/report-001/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Report README\"
available tags: [report title, report description, data analysis, results, plots, interpretation]
---

# Report README

This is a test report README.
" > "$spath"
}

md2json_report_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Report README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_report_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Report README

$content
" > "$md_file"
}

verify_md_report_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Report README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_report_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}



create_outputs_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/outputs/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Outputs README\"
available tags: [outputs description, data analysis, results, plots, interpretation]
---

# Outputs README

This is a test outputs README.
" > "$spath"
}

md2json_outputs_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Outputs README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_outputs_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Outputs README

$content
" > "$md_file"
}


verify_md_outputs_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Outputs README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_outputs_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}
create_issue_template() {
    local workspace_dir="$1"
    local timestamp="$2"
    local spath="$workspace_dir/projects/project-$project_id/issues/$timestamp-TITLE-001.md"
    ensure_sdir "$spath"
    echo "---
title: \"Issue Title\"
available tags: [issue, bug, feature, enhancement, question, discussion, high priority, low priority]
---

# Issue 001

This is a test issue.
" > "$spath"
}

md2json_issue_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Issue 001$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_issue_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Issue 001

$content
" > "$md_file"
}

verify_md_issue_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Issue 001$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_issue_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_project_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/project-$project_id/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Project README\"
available tags: [project description, project goals, project scope, project timeline, team, stakeholders, contact]
---

# Project README

This is a test project README.
" > "$spath"
}


md2json_project_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Project README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_project_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Project README

$content
" > "$md_file"
}
verify_md_project_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Project README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_project_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_projects_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/projects/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Projects README\"
available tags: [project description, project goals, project scope, project timeline, team, stakeholders, contact]
---

# Projects README

This is a test projects README.
" > "$spath"
}


md2json_projects_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Projects README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_projects_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Projects README

$content
" > "$md_file"
}

verify_md_projects_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Projects README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_projects_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_ninja_project_readme_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/README.md"
    ensure_sdir "$spath"
    echo "---
title: \"Ninja Project README\"
available tags: [project description, project goals, project scope, project timeline, team, stakeholders, contact]
---

# Ninja Project README

This is a test ninja project README.
" > "$spath"
}
md2json_ninja_project_readme_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Ninja Project README$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_ninja_project_readme_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Ninja Project README

$content
" > "$md_file"
}
verify_md_ninja_project_readme_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Ninja Project README$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_ninja_project_readme_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_memory_template() {
    local workspace_dir="$1"
    local timestamp="$2"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id/$timestamp-TITLE.md"
    ensure_sdir "$spath"
    echo "---
title: \"Memory Title\"
available tags: [memory, note, project context]
---

# Memory

This is a test memory.
" > "$spath"
}

md2json_memory_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Memory$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_memory_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")

    echo "---
title: \"$title\"
available tags: [$tags]
---

# Memory

$content
" > "$md_file"
}
verify_md_memory_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Memory$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_memory_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}

create_memory_json_template() {
    local workspace_dir="$1"
    local timestamp="$2"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id/$timestamp-TITLE.json"
    ensure_sdir "$spath"
    echo "{
  \"memory_id\": \"memory-001\",
  \"description\": \"This is a test memory.\",
    \"tags\": [\"memory\", \"test\"]
}" > "$spath"
}

create_message_json_template() {
    local workspace_dir="$1"
    local user_from="$2"
    local user_to="$3"
    local timestamp=$(date +%Y-%m-%d-%H-%M-%S)
    local spath_inbox="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/inbox/$timestamp-SUBJECT-from-$user_from-to-$user_to.json"
    local spath_outbox="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/outbox/$timestamp-SUBJECT-from-$user_to-to-$user_from.json"
    local spath_md_inbox="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/inbox/$timestamp-SUBJECT-from-$user_from-to-$user_to.md"
    local spath_md_outbox="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/outbox/$timestamp-SUBJECT-from-$user_to-to-$user_from.md"
    ensure_sdir "$spath_inbox"
    ensure_sdir "$spath_outbox"
    ensure_sdir "$spath_md_inbox"
    ensure_sdir "$spath_md_outbox"
    echo "{
        \"message_id\": \"message-001\",
        \"subject\": \"Test Subject\",
        \"from\": \"$user_from\",
        \"to\": \"$user_to\",
        \"body\": \"This is a test message.\",
        \"timestamp\": \"$timestamp\",
         \"tags\": [\"message\", \"test\"]
}" > "$spath_inbox"
    echo "{
        \"message_id\": \"message-001\",
        \"subject\": \"Test Subject\",
        \"from\": \"$user_to\",
        \"to\": \"$user_from\",
        \"body\": \"This is a test message.\",
        \"timestamp\": \"$timestamp\",
         \"tags\": [\"message\", \"test\"]
}" > "$spath_outbox"
    echo "---
title: \"Test Subject\"
available tags: [message, test]
---

# Message

This is a test message.
" > "$spath_md_inbox"
    echo "---
title: \"Test Subject\"
available tags: [message, test]
---

# Message

This is a test message.
" > "$spath_md_outbox"
}

create_status_template(){
    local workspace_dir="$1"
    local project_id="$2"
    local timestamp="$3"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/status.md"
    ensure_sdir "$spath"
    echo "---
title: \"Project Status\"
available tags: [status, progress, tasks, next_steps, notes]
---

# Project Status

## Date

$timestamp

## Tasks To Do

- [ ] Task 1
- [ ] Task 2

## In Progress

- [x] Task 3

## Completed

- [x] Task 4
- [x] Task 5

## Notes

- This is a test note.

## Reason

This is a test reason.

## Next Steps

- Step 1
- Step 2
" > "$spath"
}

md2json_status_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local date=$(sed -n '/## Date$/,/## Tasks To Do/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local tasks_todo=$(sed -n '/## Tasks To Do$/,/## In Progress/p' "$md_file" | sed '1d;$d' | sed 's/- \[ \] //g' | tr '\n' ' ')
    local in_progress=$(sed -n '/## In Progress$/,/## Completed/p' "$md_file" | sed '1d;$d' | sed 's/- \[x\] //g' | tr '\n' ' ')
    local completed=$(sed -n '/## Completed$/,/## Notes/p' "$md_file" | sed '1d;$d' | sed 's/- \[x\] //g' | tr '\n' ' ')
    local notes=$(sed -n '/## Notes$/,/## Reason/p' "$md_file" | sed '1d;$d' | sed 's/- //g' | tr '\n' ' ')
    local reason=$(sed -n '/## Reason$/,/## Next Steps/p' "$md_file" | sed '1d;$d' | tr '\n' ' ')
    local next_steps=$(sed -n '/## Next Steps$/,$p' "$md_file" | sed '1d' | sed 's/- //g' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"date\": \"$date\",
    \"current_status\": {
      \"tasks_todo\": [$(echo "$tasks_todo" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
      \"in_progress\": [$(echo "$in_progress" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
      \"completed\": [$(echo "$completed" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')]
        },
      \"notes\": \"$notes\",
    \"reason\": \"$reason\",
     \"next_steps\": [$(echo "$next_steps" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')]

  }" > "$json_file"
}

json2md_status_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local date=$(jq -r ".date" "$json_file")
    local tasks_todo=$(jq -r ".current_status.tasks_todo[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local in_progress=$(jq -r ".current_status.in_progress[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local completed=$(jq -r ".current_status.completed[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local notes=$(jq -r ".notes" "$json_file")
    local reason=$(jq -r ".reason" "$json_file")
    local next_steps=$(jq -r ".next_steps[]" "$json_file" | tr '\n' ',' | sed 's/,$//')


    echo "---
title: \"$title\"
available tags: [$tags]
---

# Project Status

## Date

$date

## Tasks To Do

$(echo "$tasks_todo" | sed 's/,/- \[ \] /g')

## In Progress

$(echo "$in_progress" | sed 's/,/- \[x\] /g')

## Completed

$(echo "$completed" | sed 's/,/- \[x\] /g')

## Notes

- $notes

## Reason

$reason

## Next Steps

$(echo "$next_steps" | sed 's/,/- /g')
" > "$md_file"
}
verify_md_status_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local date=$(sed -n '/## Date$/,/## Tasks To Do/p' "$md_file")
    if [ -z "$date" ]; then
        echo "Error: date not found in $md_file" >&2
        return 1
    fi
    local tasks_todo=$(sed -n '/## Tasks To Do$/,/## In Progress/p' "$md_file")
    if [ -z "$tasks_todo" ]; then
        echo "Error: tasks_todo not found in $md_file" >&2
        return 1
    fi
    local in_progress=$(sed -n '/## In Progress$/,/## Completed/p' "$md_file")
    if [ -z "$in_progress" ]; then
        echo "Error: in_progress not found in $md_file" >&2
        return 1
    fi
    local completed=$(sed -n '/## Completed$/,/## Notes/p' "$md_file")
    if [ -z "$completed" ]; then
        echo "Error: completed not found in $md_file" >&2
        return 1
    fi
    local notes=$(sed -n '/## Notes$/,/## Reason/p' "$md_file")
    if [ -z "$notes" ]; then
        echo "Error: notes not found in $md_file" >&2
        return 1
    fi
    local reason=$(sed -n '/## Reason$/,/## Next Steps/p' "$md_file")
    if [ -z "$reason" ]; then
        echo "Error: reason not found in $md_file" >&2
        return 1
    fi
    local next_steps=$(sed -n '/## Next Steps$/,$p' "$md_file")
    if [ -z "$next_steps" ]; then
        echo "Error: next_steps not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_status_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local date=$(jq -e ".date" "$json_file")
    if [ -z "$date" ]; then
        echo "Error: date not found in $json_file" >&2
        return 1
    fi
    local tasks_todo=$(jq -e ".current_status.tasks_todo" "$json_file")
    if [ -z "$tasks_todo" ]; then
        echo "Error: tasks_todo not found in $json_file" >&2
        return 1
    fi
    local in_progress=$(jq -e ".current_status.in_progress" "$json_file")
    if [ -z "$in_progress" ]; then
        echo "Error: in_progress not found in $json_file" >&2
        return 1
    fi
    local completed=$(jq -e ".current_status.completed" "$json_file")
    if [ -z "$completed" ]; then
        echo "Error: completed not found in $json_file" >&2
        return 1
    fi
    local notes=$(jq -e ".notes" "$json_file")
    if [ -z "$notes" ]; then
        echo "Error: notes not found in $json_file" >&2
        return 1
    fi
    local reason=$(jq -e ".reason" "$json_file")
    if [ -z "$reason" ]; then
        echo "Error: reason not found in $json_file" >&2
        return 1
    fi
    local next_steps=$(jq -e ".next_steps" "$json_file")
    if [ -z "$next_steps" ]; then
        echo "Error: next_steps not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}


create_tasks_json_template() {
    local workspace_dir="$1"
    local project_id="$2"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/.tasks.json"
    ensure_sdir "$spath"
    echo "{
  \"tasks_id\": \"tasks-001\",
  \"description\": \"This is a tasks list.\",
  \"tasks\": [
    {
      \"task_id\": \"task-001\",
      \"description\": \"This is a test task.\",
      \"status\": \"todo\",
      \"tags\": [\"task\", \"test\"]
    }
    ]
}" > "$spath"
}

create_forum_template() {
    local workspace_dir="$1"
    local project_id="$2"
    local spath="$workspace_dir/projects/project-$project_id/forum.md"
    ensure_sdir "$spath"
    echo "---
title: \"Project Forum\"
available tags: [forum, discussion, question, answer, idea, suggestion, request, feedback]
---

# Project Forum

This is a test project forum.
" > "$spath"
}
md2json_forum_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Project Forum$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_forum_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Project Forum

$content
" > "$md_file"
}
verify_md_forum_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Project Forum$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_forum_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}
create_forum_json_template() {
    local workspace_dir="$1"
    local project_id="$2"
    local spath="$workspace_dir/projects/project-$project_id/.forum.json"
    ensure_sdir "$spath"
    echo "{
  \"forum_id\": \"forum-001\",
  \"description\": \"This is a project forum.\",
  \"entries\": [
    {
      \"entry_id\": \"entry-001\",
      \"content\": \"This is a test forum entry.\",
       \"tags\": [\"forum\", \"test\"]
    }
    ]
}" > "$spath"
}

create_profile_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/profile.md"
    ensure_sdir "$spath"
    echo "---
title: \"Ninja Profile\"
available tags: [ninja, skills, expertise, interests, goals]
---

# Ninja Profile

This is a test ninja profile.
" > "$spath"
}

md2json_profile_template() {
    local md_file="$1"
    local json_file="${md_file%.md}.json"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file" | sed 's/^title: "//;s/"$//')
    local tags=$(grep "^available tags: " "$md_file" | sed 's/^available tags: \[//;s/\]$//' | tr ',' ' ')
    local content=$(sed -n '/# Ninja Profile$/, $p' "$md_file" | sed '1d' | tr '\n' ' ')
    echo "{
    \"title\": \"$title\",
    \"available_tags\": [$(echo "$tags" | sed 's/ /", "/g' | sed 's/^/"/;s/$/"/')],
    \"content\": \"$content\"
    }" > "$json_file"
}

json2md_profile_template() {
    local json_file="$1"
    local md_file="${json_file%.json}.md"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -r ".title" "$json_file")
    local tags=$(jq -r ".available_tags[]" "$json_file" | tr '\n' ',' | sed 's/,$//')
    local content=$(jq -r ".content" "$json_file")
    echo "---
title: \"$title\"
available tags: [$tags]
---

# Ninja Profile

$content
" > "$md_file"
}
verify_md_profile_template() {
    local md_file="$1"
    if [ ! -f "$md_file" ]; then
        echo "Error: Markdown file not found: $md_file" >&2
        return 1
    fi
    local title=$(grep "^title: " "$md_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $md_file" >&2
        return 1
    fi
    local tags=$(grep "^available tags: " "$md_file")
    if [ -z "$tags" ]; then
        echo "Error: available tags not found in $md_file" >&2
        return 1
    fi
    local content=$(sed -n '/# Ninja Profile$/, $p' "$md_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $md_file" >&2
        return 1
    fi
    echo "Markdown file $md_file is valid"
    return 0
}

verify_json_profile_template() {
    local json_file="$1"
    if [ ! -f "$json_file" ]; then
        echo "Error: JSON file not found: $json_file" >&2
        return 1
    fi
    local title=$(jq -e ".title" "$json_file")
    if [ -z "$title" ]; then
        echo "Error: title not found in $json_file" >&2
        return 1
    fi
    local tags=$(jq -e ".available_tags" "$json_file")
    if [ -z "$tags" ]; then
        echo "Error: available_tags not found in $json_file" >&2
        return 1
    fi
    local content=$(jq -e ".content" "$json_file")
    if [ -z "$content" ]; then
        echo "Error: content not found in $json_file" >&2
        return 1
    fi
    echo "JSON file $json_file is valid"
    return 0
}
create_profile_json_template() {
    local workspace_dir="$1"
    local spath="$workspace_dir/ninjas/ninja-$ninja_id/.profile.json"
    ensure_sdir "$spath"
    echo "{
  \"profile_id\": \"profile-001\",
  \"description\": \"This is a ninja profile.\",
   \"tags\": [\"ninja\", \"test\"]
}" > "$spath"
}

setup_workspace() {
    local workspace_dir="/workspace"
    local timestamp=$(date +%Y-%m-%d-%H-%M-%S)
    local project_id="001"
    local ninja_id="001"
    local user1="USER1"
    local user2="USER2"

    # Create directories
    mkdir -p "$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id"
    mkdir -p "$workspace_dir/ninjas/ninja-$ninja_id/messages/inbox"
    mkdir -p "$workspace_dir/ninjas/ninja-$ninja_id/messages/outbox"
    mkdir -p "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/inbox"
    mkdir -p "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/outbox"
    mkdir -p "$workspace_dir/projects/project-$project_id/data"
    mkdir -p "$workspace_dir/projects/project-$project_id/docs"
    mkdir -p "$workspace_dir/projects/project-$project_id/outputs/report-001"
    mkdir -p "$workspace_dir/projects/project-$project_id/issues"
    mkdir -p "$workspace_dir/shared/agents/templates"
    mkdir -p "$workspace_dir/shared/agents/configs"
    mkdir -p "$workspace_dir/shared/system/logs"
    mkdir -p "$workspace_dir/shared/prompts"
    mkdir -p "$workspace_dir/shared/tools/tool-001"
    mkdir -p "$workspace_dir/shared/knowledge_base"


    # Create files
    touch "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/inbox/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/messages/outbox/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/messages/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/messages/inbox/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/messages/outbox/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/memory/README.md"
    touch "$workspace_dir/projects/project-$project_id/scripts/README.md"
    touch "$workspace_dir/ninjas/ninja-$ninja_id/README.md"


    # Create symlink
    ln -s "$workspace_dir/projects/project-$project_id/data" "$workspace_dir/projects/project-$project_id/outputs/report-001/data"

    # Create Templates
    create_agent_template "$workspace_dir"
    create_agent_config "$workspace_dir"
    create_system_log_template "$workspace_dir"
    create_tool_md_template "$workspace_dir"
    create_prompt_template "$workspace_dir"
    create_knowledge_base_template "$workspace_dir"
    create_data_readme_template "$workspace_dir"
    create_docs_readme_template "$workspace_dir"
    create_report_readme_template "$workspace_dir"
    create_outputs_readme_template "$workspace_dir"
    create_issue_template "$workspace_dir" "$timestamp"
    create_project_readme_template "$workspace_dir"
    create_projects_readme_template "$workspace_dir"
    create_ninja_project_readme_template "$workspace_dir"
    create_memory_template "$workspace_dir" "$timestamp"
    create_message_json_template "$workspace_dir" "$user1" "$user2"
    create_status_template "$workspace_dir" "$project_id" "$timestamp"
    create_tasks_json_template "$workspace_dir" "$project_id"
    create_forum_template "$workspace_dir" "$project_id"
    create_profile_template "$workspace_dir"
    create_tool_json_template "$workspace_dir"
    create_tool_schema_template "$workspace_dir"
    create_prompt_json_template "$workspace_dir"
    create_memory_json_template "$workspace_dir" "$timestamp"
    create_forum_json_template "$workspace_dir" "$project_id"
    create_profile_json_template "$workspace_dir"

    # Create md to json

    md2json_agent_template "$workspace_dir/shared/agents/templates/agent-template.md"
    md2json_agent_config "$workspace_dir/shared/agents/configs/.agent-config.md"
    md2json_tool_template "$workspace_dir/shared/tools/tool-001/tool.md"
    md2json_prompt_template "$workspace_dir/shared/prompts/prompt-template.md"
    md2json_knowledge_base_template "$workspace_dir/shared/knowledge_base/.knowledge.md"
    md2json_data_readme_template "$workspace_dir/projects/project-$project_id/data/README.md"
    md2json_docs_readme_template "$workspace_dir/projects/project-$project_id/docs/README.md"
    md2json_report_readme_template "$workspace_dir/projects/project-$project_id/outputs/report-001/README.md"
    md2json_outputs_readme_template "$workspace_dir/projects/project-$project_id/outputs/README.md"
    md2json_issue_template "$workspace_dir/projects/project-$project_id/issues/$timestamp-TITLE-001.md"
    md2json_project_readme_template "$workspace_dir/projects/project-$project_id/README.md"
    md2json_projects_readme_template "$workspace_dir/projects/README.md"
    md2json_ninja_project_readme_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/README.md"
    md2json_memory_template "$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id/$timestamp-TITLE.md"
    md2json_status_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/status.md"
    md2json_forum_template "$workspace_dir/projects/project-$project_id/forum.md"
    md2json_profile_template "$workspace_dir/ninjas/ninja-$ninja_id/profile.md"

    #verify json and md
    verify_json_agent_template "$workspace_dir/shared/agents/templates/agent-template.json"
    verify_md_agent_template "$workspace_dir/shared/agents/templates/agent-template.md"
    verify_json_agent_config "$workspace_dir/shared/agents/configs/.agent-config.json"
    verify_md_agent_config "$workspace_dir/shared/agents/configs/.agent-config.md"
    verify_json_tool_template "$workspace_dir/shared/tools/.tool-001.json"
    verify_md_tool_template "$workspace_dir/shared/tools/tool-001/tool.md"
    verify_json_prompt_template "$workspace_dir/shared/prompts/.prompt-template.json"
    verify_md_prompt_template "$workspace_dir/shared/prompts/prompt-template.md"
    verify_json_knowledge_base_template "$workspace_dir/shared/knowledge_base/.knowledge.json"
    verify_md_knowledge_base_template "$workspace_dir/shared/knowledge_base/.knowledge.md"
    verify_json_data_readme_template "$workspace_dir/projects/project-$project_id/data/.README.json"
    verify_md_data_readme_template "$workspace_dir/projects/project-$project_id/data/README.md"
    verify_json_docs_readme_template "$workspace_dir/projects/project-$project_id/docs/.README.json"
    verify_md_docs_readme_template "$workspace_dir/projects/project-$project_id/docs/README.md"
    verify_json_report_readme_template "$workspace_dir/projects/project-$project_id/outputs/report-001/.README.json"
    verify_md_report_readme_template "$workspace_dir/projects/project-$project_id/outputs/report-001/README.md"
    verify_json_outputs_readme_template "$workspace_dir/projects/project-$project_id/outputs/.README.json"
    verify_md_outputs_readme_template "$workspace_dir/projects/project-$project_id/outputs/README.md"
    verify_json_issue_template "$workspace_dir/projects/project-$project_id/issues/$timestamp-TITLE-001.json"
    verify_md_issue_template "$workspace_dir/projects/project-$project_id/issues/$timestamp-TITLE-001.md"
    verify_json_project_readme_template "$workspace_dir/projects/project-$project_id/.README.json"
    verify_md_project_readme_template "$workspace_dir/projects/project-$project_id/README.md"
    verify_json_projects_readme_template "$workspace_dir/projects/.README.json"
    verify_md_projects_readme_template "$workspace_dir/projects/README.md"
    verify_json_ninja_project_readme_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/.README.json"
    verify_md_ninja_project_readme_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/README.md"
    verify_json_memory_template "$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id/$timestamp-TITLE.json"
    verify_md_memory_template "$workspace_dir/ninjas/ninja-$ninja_id/memory/projects/$project_id/$timestamp-TITLE.md"
    verify_json_status_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/.status.json"
    verify_md_status_template "$workspace_dir/ninjas/ninja-$ninja_id/projects/project-$project_id/status.md"
    verify_json_forum_template "$workspace_dir/projects/project-$project_id/.forum.json"
    verify_md_forum_template "$workspace_dir/projects/project-$project_id/forum.md"
    verify_json_profile_template "$workspace_dir/ninjas/ninja-$ninja_id/.profile.json"
    verify_md_profile_template "$workspace_dir/ninjas/ninja-$ninja_id/profile.md"

    # Create dummy data file
    echo "This is a dummy dataset." > "$workspace_dir/projects/project-$project_id/data/dataset.txt"
    echo "This is a dummy report." > "$workspace_dir/projects/project-$project_id/outputs/report-001/report.pdf"


    echo ""
    echo "========================================"
    echo "Workspace setup complete in $workspace_dir"
    echo "========================================"
    echo ""
    tree "$workspace_dir/ninjas"
    echo ""
    tree "$workspace_dir/projects"
    echo ""
    tree "$workspace_dir/shared"
    echo ""
}

rm -rf /workspace/ninjas
rm -rf /workspace/projects
rm -rf /workspace/shared

# apt-get update && apt-get install -y jq
setup_workspace