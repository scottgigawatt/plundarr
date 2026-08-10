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
    """Extract one Compose service with its leading project comments.

    Args:
        source: Complete Compose source containing a top-level services section.
        service_name: Exact service key to extract.

    Returns:
        The selected service block with one trailing newline.

    Raises:
        TemplateError: If the services section or requested service is absent.

    Note:
        This intentionally avoids YAML parsing so operator-facing comments and
        unresolved Compose variables survive generation verbatim.
    """
    lines = source.splitlines(keepends=True)
    try:
        services_index = next(
            index for index, line in enumerate(lines) if line.rstrip() == "services:"
        )
    except StopIteration as error:
        raise TemplateError("Compose source does not contain a services section.") from error

    # Service declarations are the only two-space keys in the owned services
    # section. Stop at the next top-level key instead of scanning unrelated YAML.
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
    # Walk backward across only blank and service-indented comment lines so the
    # selected service retains its purpose banner without stealing its neighbor.
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
    """Extract shared anchors and the opening services key.

    Args:
        source: Complete project-owned base Compose template.

    Returns:
        Foundation text ending immediately after ``services:``.

    Raises:
        TemplateError: If either required structural marker is absent.
    """
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
    """Extract the final networks section from the base Compose template.

    Args:
        source: Complete project-owned base Compose template.

    Returns:
        Footer text beginning at the networks purpose comment.

    Raises:
        TemplateError: If the networks marker is absent.
    """
    marker = "#\n# Define the networks section.\n#\nnetworks:\n"
    start = source.find(marker)
    if start < 0:
        raise TemplateError("Compose networks marker was not found.")
    return source[start:].strip("\n") + "\n"


def extract_env_preamble(source: str) -> str:
    """Extract the copyright and description preamble from an environment file.

    Args:
        source: Complete project-owned environment source.

    Returns:
        Preamble text ending before the first setting group.

    Raises:
        TemplateError: If the first setting marker is absent.
    """
    first_setting = "#\n# Name of the project which adds namespace for all services and volumes.\n#\n"
    end = source.find(first_setting)
    if end < 0:
        raise TemplateError("Environment preamble marker was not found.")
    return source[:end].rstrip("\n") + "\n\n"


def extract_env_sections(source: str) -> dict[str, str]:
    """Split framed environment sections while retaining comments verbatim.

    Args:
        source: Complete project-owned environment source.

    Returns:
        Ordered mapping of section titles to newline-terminated source blocks.
        Copyright and file-description frames are excluded.
    """
    matches = list(ENV_HEADER_PATTERN.finditer(source))
    sections: dict[str, str] = {}
    for position, match in enumerate(matches):
        title = match.group("title")
        # Header frames share the same visual syntax as setting groups but are
        # file metadata, not selectable environment content.
        if title.startswith(("Copyright ", "Licensed under ", ".env file:")):
            continue
        end = matches[position + 1].start() if position + 1 < len(matches) else len(source)
        sections[title] = source[match.start():end].strip("\n") + "\n"
    return sections


def strip_yaml_key(block: str, key: str) -> str:
    """Remove one service-level YAML key and its nested content.

    Args:
        block: Extracted Compose service block.
        key: Exact four-space key name to remove.

    Returns:
        The normalized block, unchanged when the key is absent.
    """
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
    # Include the key's immediately preceding comment banner and blank line so
    # conditional removal does not leave misleading orphaned documentation.
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
    """Remove one Homepage environment group identified by its heading.

    Args:
        block: Homepage Compose service block.
        heading: Exact project-owned comment text introducing the group.

    Returns:
        The normalized block, unchanged when the heading is absent.
    """
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
    """Format a logical YAML group with aligned inline comments.

    Args:
        entries: Ordered ``(code, comment)`` pairs without indentation.
        indent: Number of leading spaces applied to every output line.

    Returns:
        Newline-separated YAML lines, or an empty string for no entries.
    """
    if not entries:
        return ""
    prefix = " " * indent
    width = max(len(code) for code, _ in entries)
    return "\n".join(
        f"{prefix}{code.ljust(width)}  # {comment}" for code, comment in entries
    )
