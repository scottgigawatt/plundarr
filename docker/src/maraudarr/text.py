#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# text.py: Comment-preserving Compose and environment text helpers.
#

"""Extract and format source fragments without discarding project comments."""

from __future__ import annotations

import re


SERVICE_PATTERN = re.compile(r"^  ([A-Za-z0-9][A-Za-z0-9_-]*):\s*$")
ENV_HEADER_PATTERN = re.compile(r"^#\n# (?P<title>[^\n]+)\n#\n", re.MULTILINE)


class TemplateError(ValueError):
    """Raised when a source template does not match the expected structure."""


def extract_service(source: str, service_name: str) -> str:
    """Extract one service and its leading comments without parsing YAML."""

    lines = source.splitlines(keepends=True)
    try:
        services_index = next(
            index for index, line in enumerate(lines) if line.rstrip() == "services:"
        )
    except StopIteration as error:
        raise TemplateError("Compose source does not contain a services section.") from error

    declarations: list[tuple[str, int]] = []
    for index in range(services_index + 1, len(lines)):
        match = SERVICE_PATTERN.match(lines[index].rstrip("\n"))
        if match:
            declarations.append((match.group(1), index))
        elif lines[index] and not lines[index].startswith((" ", "\n", "\r")):
            break

    names = [name for name, _ in declarations]
    if service_name not in names:
        raise TemplateError(f"Service '{service_name}' was not found in its source file.")

    position = names.index(service_name)
    declaration_index = declarations[position][1]
    start = declaration_index
    while start > services_index + 1:
        previous = lines[start - 1]
        if previous.strip() == "" or previous.startswith("  #"):
            start -= 1
            continue
        break

    if position + 1 < len(declarations):
        next_declaration = declarations[position + 1][1]
        end = next_declaration
        while end > declaration_index:
            previous = lines[end - 1]
            if previous.strip() == "" or previous.startswith("  #"):
                end -= 1
                continue
            break
    else:
        end = len(lines)
        for index in range(declaration_index + 1, len(lines)):
            if lines[index] and not lines[index].startswith((" ", "\n", "\r")):
                end = index
                break

    return "".join(lines[start:end]).strip("\n") + "\n"


def extract_foundation(source: str) -> str:
    """Extract anchors and the opening services key from the base Compose file."""

    marker = "#\n# Setup default properties for all or most containers.\n#\n"
    start = source.find(marker)
    if start < 0:
        raise TemplateError("Compose foundation marker was not found.")
    services_marker = "#\n# Define the services section.\n#\nservices:\n"
    end = source.find(services_marker, start)
    if end < 0:
        raise TemplateError("Compose services marker was not found.")
    end += len(services_marker)
    return source[start:end]


def extract_footer(source: str) -> str:
    """Extract the networks section from the base Compose file."""

    marker = "#\n# Define the networks section.\n#\nnetworks:\n"
    start = source.find(marker)
    if start < 0:
        raise TemplateError("Compose networks marker was not found.")
    return source[start:].strip("\n") + "\n"


def extract_env_preamble(source: str) -> str:
    """Return the copyright and file-description block from example.env."""

    first_setting = "#\n# Name of the project which adds namespace for all services and volumes.\n#\n"
    end = source.find(first_setting)
    if end < 0:
        raise TemplateError("Environment preamble marker was not found.")
    return source[:end].rstrip("\n") + "\n\n"


def extract_env_sections(source: str) -> dict[str, str]:
    """Split framed environment sections while retaining comments verbatim."""

    matches = list(ENV_HEADER_PATTERN.finditer(source))
    sections: dict[str, str] = {}
    for position, match in enumerate(matches):
        title = match.group("title")
        if title.startswith(("Copyright ", "Licensed under ", ".env file:")):
            continue
        end = matches[position + 1].start() if position + 1 < len(matches) else len(source)
        sections[title] = source[match.start():end].strip("\n") + "\n"
    return sections


def strip_yaml_key(block: str, key: str) -> str:
    """Remove a four-space service key and its nested content."""

    lines = block.splitlines(keepends=True)
    start = None
    end = len(lines)
    target = f"    {key}:"
    for index, line in enumerate(lines):
        if line.rstrip() == target:
            start = index
            break
    if start is None:
        return block
    key_start = start
    while start > 0 and lines[start - 1].startswith("    #"):
        start -= 1
    while start > 0 and lines[start - 1].strip() == "":
        start -= 1
    for index in range(key_start + 1, len(lines)):
        line = lines[index]
        if line.startswith("    ") and not line.startswith("      ") and line.strip():
            end = index
            break
    return "".join(lines[:start] + lines[end:]).rstrip("\n") + "\n"


def remove_comment_group(block: str, heading: str) -> str:
    """Remove one Homepage environment group beginning at a comment heading."""

    marker = f"      # {heading}\n"
    start = block.find(marker)
    if start < 0:
        return block
    next_heading = block.find("\n      # Homepage ", start + len(marker))
    if next_heading < 0:
        next_heading = block.find("\n    # ", start + len(marker))
    if next_heading < 0:
        next_heading = len(block)
    return block[:start].rstrip() + "\n\n" + block[next_heading + 1 :].lstrip("\n")


def aligned_yaml_lines(entries: list[tuple[str, str]], indent: int) -> str:
    """Format logically grouped YAML lines with aligned inline comments."""

    if not entries:
        return ""
    prefix = " " * indent
    width = max(len(code) for code, _ in entries)
    return "\n".join(
        f"{prefix}{code.ljust(width)}  # {comment}" for code, comment in entries
    )
