#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# render.py: Generate Plundarr Compose, environment, and config artifacts.
#

"""Render selected services without discarding handwritten source comments."""

from __future__ import annotations

import base64
import os
import re
import secrets
import shutil
import subprocess
import tempfile
from pathlib import Path

from maraudarr.catalog import Catalog
from maraudarr.models import StackPlan
from maraudarr.text import (
    aligned_yaml_lines,
    extract_footer,
    extract_foundation,
    extract_service,
    remove_comment_group,
    strip_yaml_key,
)


class RenderError(RuntimeError):
    """Raised when generation or Compose validation fails."""


def render_header(plan: StackPlan) -> str:
    """Render the established header and selected-service manifest.

    Args:
        plan: Resolved stack plan supplying summary text and service order.

    Returns:
        Commented Compose header ending with one blank line.
    """
    summary = "\n".join(f"# {line}" if line else "#" for line in plan.preset.compose_summary)
    service_width = max(len(service.service) + 1 for service in plan.services) + 2
    services = "\n".join(
        f"#   - {(service.service + ':').ljust(service_width)}{service.url}"
        for service in plan.services
    )
    return (
        "#\n"
        "# Copyright 2025-2026 Scott Gigawatt\n"
        "#\n"
        "# Licensed under the Apache License, Version 2.0.\n"
        "#\n"
        f"{summary}\n"
        "#\n"
        "# Services included:\n"
        f"{services}\n"
        "#\n\n"
    )


def _insert_gluetun_additions(block: str, selected: set[str]) -> str:
    """Insert downloader-specific Gluetun commands and published ports."""
    environment_entries: list[tuple[str, str]] = []
    port_entries: list[tuple[str, str]] = []
    if "qbittorrent" in selected:
        environment_entries.extend(
            [
                (
                    'VPN_PORT_FORWARDING_UP_COMMAND: /bin/sh -c "${GLUETUN_QBITTORRENT_PORT_FORWARDING_SCRIPT} up {{PORT}} {{VPN_INTERFACE}}"',
                    "Update qBittorrent when PIA assigns a forwarded port",
                ),
                (
                    'VPN_PORT_FORWARDING_DOWN_COMMAND: /bin/sh -c "${GLUETUN_QBITTORRENT_PORT_FORWARDING_SCRIPT} down"',
                    "Clear qBittorrent's forwarded port during shutdown",
                ),
            ]
        )
        port_entries.extend(
            [
                ("- ${QBITTORRENT_TCP_PORT}:6881", "qBittorrent TCP connection port"),
                ("- ${QBITTORRENT_UDP_PORT}:6881/udp", "qBittorrent UDP connection port"),
                ("- ${QBITTORRENT_WEBUI_PORT}:8080", "qBittorrent web UI port"),
            ]
        )
    if "sabnzbd" in selected:
        port_entries.append(("- ${SABNZBD_WEBUI_PORT}:8085", "SABnzbd web UI port"))
    if "nzbget" in selected:
        port_entries.append(("- ${NZBGET_WEBUI_PORT}:6789", "NZBGet web UI port"))

    if environment_entries:
        anchor = (
            "      PRIVATEERR_GLUETUN_METADATA_WAIT_SECONDS: "
            "${PRIVATEERR_GLUETUN_METADATA_WAIT_SECONDS}\n"
        )
        insertion = (
            "\n      # Define downloader port-forwarding commands for Gluetun\n"
            + aligned_yaml_lines(environment_entries, 6)
            + "\n"
        )
        block = block.replace(anchor, anchor + insertion, 1)

    if port_entries:
        anchor = "    # Mount host directories into the container\n"
        insertion = (
            "    # Define downloader host and container ports\n"
            "    ports:\n"
            + aligned_yaml_lines(port_entries, 6)
            + "\n\n"
        )
        block = block.replace(anchor, insertion + anchor, 1)
    return block


def _prepare_service(
    block: str,
    service_id: str,
    selected: set[str],
    include_native_plex: bool,
    media_libraries: tuple[str, ...],
) -> str:
    """Apply service-specific conditional edits to one extracted chart."""
    if service_id == "gluetun":
        block = _insert_gluetun_additions(block, selected)
    # These applications can operate without their catalog recommendations;
    # remove template dependencies that were intentionally left unselected.
    if service_id in {"cleanuparr", "whisparr"}:
        block = strip_yaml_key(block, "depends_on")
    if service_id == "plex":
        library_variables = {
            "anime": "${HOST_ANIME_TV_PATH}",
            "movies": "${HOST_MOVIES_PATH}",
            "scenes": "${HOST_SCENES_PATH}",
            "tv": "${HOST_TV_PATH}",
        }
        excluded_variables = {
            variable
            for library, variable in library_variables.items()
            if library not in media_libraries
        }
        block = "\n".join(
            line
            for line in block.splitlines()
            if not any(variable in line for variable in excluded_variables)
        )
    if service_id == "homepage":
        homepage_groups = {
            "Homepage Plex click target and widget": include_native_plex,
            "Homepage Tautulli click target and widget": include_native_plex,
            "Homepage Radarr click target and widget": "radarr" in selected,
            "Homepage Sonarr click target and widget": "sonarr" in selected,
            "Homepage Bazarr click target and widget": "bazarr" in selected,
            "Homepage Seerr click target and widget": "seerr" in selected,
            "Homepage Prowlarr click target and widget": "prowlarr" in selected,
            "Homepage qBittorrent click target and widget": "qbittorrent" in selected,
            "Homepage SABnzbd click target and widget": "sabnzbd" in selected,
            "Homepage NZBGet click target and widget": "nzbget" in selected,
            "Homepage Speedtest Tracker click target and widget": (
                "speedtest-tracker" in selected
            ),
        }
        for heading, keep in homepage_groups.items():
            if not keep:
                block = remove_comment_group(block, heading)
        if "sonarr-anime" in selected:
            anchor = "\n      # Homepage Bazarr click target and widget"
            if anchor not in block:
                anchor = "\n    # Define the host and container ports"
            insertion = (
                "\n      # Homepage Sonarr Anime click target and widget\n"
                "      HOMEPAGE_VAR_SONARR_ANIME_HREF: ${HOMEPAGE_VAR_SONARR_ANIME_HREF}                           # Homepage Sonarr Anime click target\n"
                "      HOMEPAGE_VAR_SONARR_ANIME_URL: ${HOMEPAGE_VAR_SONARR_ANIME_URL}:${SONARR_ANIME_WEBUI_PORT}  # Homepage Sonarr Anime widget URL\n"
                "      HOMEPAGE_VAR_SONARR_ANIME_KEY: ${HOMEPAGE_VAR_SONARR_ANIME_KEY}                             # Homepage Sonarr Anime API key\n"
                "      HOMEPAGE_VAR_SONARR_ANIME_CONTAINER: ${COMPOSE_PROJECT_NAME}-sonarr-anime-${SONARR_ANIME_TAG}  # Homepage Sonarr Anime container\n"
            )
            block = block.replace(anchor, insertion + anchor, 1)
        if "jellyfin" in selected:
            anchor = "\n      # Homepage Speedtest Tracker click target and widget"
            if anchor not in block:
                anchor = "\n    # Define the host and container ports"
            insertion = (
                "\n      # Homepage Jellyfin click target and widget\n"
                "      HOMEPAGE_VAR_JELLYFIN_HREF: ${HOMEPAGE_VAR_JELLYFIN_HREF}                         # Homepage Jellyfin click target\n"
                "      HOMEPAGE_VAR_JELLYFIN_URL: ${HOMEPAGE_VAR_JELLYFIN_URL}:${JELLYFIN_WEBUI_PORT}  # Homepage Jellyfin widget URL\n"
                "      HOMEPAGE_VAR_JELLYFIN_KEY: ${HOMEPAGE_VAR_JELLYFIN_KEY}                         # Homepage Jellyfin API key\n"
            )
            block = block.replace(anchor, insertion + anchor, 1)
    return block.rstrip("\n") + "\n"


def render_compose(catalog: Catalog, plan: StackPlan) -> str:
    """Render the complete comment-rich Compose file.

    Args:
        catalog: Validated source catalog containing templates and charts.
        plan: Resolved service selection in deterministic output order.

    Returns:
        A single Compose document with unresolved environment variables and
        project-owned comments preserved.

    Raises:
        TemplateError: If an owned Compose source no longer contains an
            expected service, foundation, footer, or comment group.
        OSError: If a required source file cannot be read.
    """
    base_source = catalog.source_path("templates/compose.yml").read_text()
    selected = set(plan.service_ids)
    include_native_plex = plan.preset.id == "plundarr" or "plex" in selected
    service_blocks = []
    for service in plan.services:
        source = catalog.source_path(service.compose).read_text()
        block = extract_service(source, service.service)
        service_blocks.append(
            _prepare_service(
                block,
                service.id,
                selected,
                include_native_plex,
                plan.preset.media_libraries,
            )
        )

    return (
        render_header(plan)
        + extract_foundation(base_source)
        + "\n\n".join(block.rstrip("\n") for block in service_blocks)
        + "\n\n"
        + extract_footer(base_source)
    )


def _filter_homepage_env(
    section: str,
    selected: set[str],
    include_native_plex: bool,
) -> str:
    """Remove Homepage environment groups for unavailable integrations."""
    groups = {
        "Homepage Plex click-target and widget variables": include_native_plex,
        "Homepage Tautulli click-target and widget variables": include_native_plex,
        "Homepage Radarr click-target and widget variables": "radarr" in selected,
        "Homepage Sonarr click-target and widget variables": "sonarr" in selected,
        "Homepage Sonarr Anime click-target and widget variables": (
            "sonarr-anime" in selected
        ),
        "Homepage Jellyfin click-target and widget variables": "jellyfin" in selected,
        "Homepage Bazarr click-target and widget variables": "bazarr" in selected,
        "Homepage Seerr click-target and widget variables": "seerr" in selected,
        "Homepage Prowlarr click-target and widget variables": "prowlarr" in selected,
        "Homepage qBittorrent click-target and widget variables": (
            "qbittorrent" in selected
        ),
        "Homepage SABnzbd click-target and widget variables": "sabnzbd" in selected,
        "Homepage NZBGet click-target and widget variables": "nzbget" in selected,
        "Homepage Speedtest Tracker click-target and widget variables": (
            "speedtest-tracker" in selected
        ),
    }
    for heading, keep in groups.items():
        if keep:
            continue
        # Homepage environment groups use stable project-owned headings. Work
        # between headings so comments and assignment order remain untouched.
        marker = f"# {heading}\n"
        start = section.find(marker)
        if start < 0:
            continue
        next_group = section.find("\n# Homepage ", start + len(marker))
        end = len(section) if next_group < 0 else next_group + 1
        section = section[:start].rstrip() + "\n\n" + section[end:].lstrip("\n")
    return section.rstrip("\n") + "\n"


def _existing_values(path: Path) -> dict[str, str]:
    """Index existing assignment lines without evaluating their values."""
    if not path.exists():
        return {}
    values: dict[str, str] = {}
    assignment = re.compile(r"^(?P<key>[A-Za-z_][A-Za-z0-9_]*)=")
    for line in path.read_text().splitlines():
        match = assignment.match(line)
        if match:
            values[match.group("key")] = line
    return values


def _assignment_keys(source: str) -> set[str]:
    """Return assignment names found at the start of environment lines."""
    assignment = re.compile(r"^(?P<key>[A-Za-z_][A-Za-z0-9_]*)=", re.MULTILINE)
    return {match.group("key") for match in assignment.finditer(source)}


def _preserve_values(rendered: str, existing: dict[str, str]) -> str:
    """Replace rendered assignments with matching user-managed lines."""
    assignment = re.compile(r"^(?P<key>[A-Za-z_][A-Za-z0-9_]*)=")
    lines = []
    for line in rendered.splitlines():
        match = assignment.match(line)
        if (
            match
            and match.group("key") != "COMPOSE_PROJECT_NAME"
            and match.group("key") in existing
        ):
            lines.append(existing[match.group("key")])
        else:
            lines.append(line)
    return "\n".join(lines).rstrip() + "\n"


def _preserve_inactive_values(
    rendered: str,
    existing: dict[str, str],
    known_keys: set[str],
) -> str:
    """Keep known settings when their service is temporarily unselected.

    Only keys owned by current catalog sources are retained. Unknown or removed
    settings are not carried forward indefinitely.
    """
    active_keys = _assignment_keys(rendered)
    inactive = [
        line
        for key, line in existing.items()
        if key != "COMPOSE_PROJECT_NAME"
        and key in known_keys
        and key not in active_keys
    ]
    if not inactive:
        return rendered
    return (
        rendered.rstrip()
        + "\n\n#\n"
        + "# Preserved values for services not selected in this stack\n"
        + "#\n"
        + "\n".join(inactive)
        + "\n"
    )


def _generate_first_run_secrets(rendered: str, existing: dict[str, str]) -> str:
    """Replace known placeholders only when no existing assignment is present."""
    generated = {
        "SPEEDTEST_TRACKER_APP_KEY": (
            "base64:" + base64.b64encode(secrets.token_bytes(32)).decode("ascii")
        ),
        "DUPLICATI_SETTINGS_ENCRYPTION_KEY": secrets.token_urlsafe(32),
        "DUPLICATI_WEBSERVICE_PASSWORD": secrets.token_urlsafe(18),
        "NZBGET_PASS": secrets.token_urlsafe(18),
    }
    for key, value in generated.items():
        if key in existing:
            continue
        rendered = re.sub(
            rf"^{re.escape(key)}=.*$",
            f'{key}="{value}"',
            rendered,
            count=1,
            flags=re.MULTILINE,
        )
    return rendered


def render_environment(
    catalog: Catalog,
    plan: StackPlan,
    existing_path: Path | None,
    generate_secrets: bool = True,
) -> str:
    """Render the selected environment while preserving user-managed values.

    Args:
        catalog: Validated catalog containing environment source fragments.
        plan: Resolved service selection in deterministic output order.
        existing_path: Existing ``.env`` file whose assignment lines should be
            preserved. No prior values are loaded when this value is absent.
        generate_secrets: Whether known first-run placeholders should receive
            cryptographically strong generated values.

    Returns:
        The complete environment document with a trailing newline.

    Raises:
        OSError: If a source or existing environment file cannot be read.
    """
    base_source = catalog.source_path("templates/environment.env").read_text()
    selected = set(plan.service_ids)
    include_plex_homepage = plan.preset.id == "plundarr" or "plex" in selected
    rendered_sections = [base_source]
    for service in plan.services:
        section = catalog.source_path(service.environment).read_text()
        if service.id == "homepage":
            section = _filter_homepage_env(
                section,
                selected,
                include_plex_homepage,
            )
        rendered_sections.append(section)

    rendered = "\n\n".join(
        section.rstrip("\n") for section in rendered_sections
    )
    # Fresh environments inherit identity, network, and media defaults from
    # the selected preset. Existing user-managed values remain preserved below.
    media_root = plan.preset.media_root.rstrip("/")
    preset_defaults = {
        "COMPOSE_PROJECT_NAME": ("plundarr", plan.preset.project_name),
        "COMPOSE_NETWORK_SUBNET": ("172.28.0.0/16", plan.preset.network_subnet),
        "COMPOSE_NETWORK_IP_RANGE": (
            "172.28.5.0/24",
            plan.preset.network_ip_range,
        ),
        "COMPOSE_NETWORK_GATEWAY": (
            "172.28.5.254",
            plan.preset.network_gateway,
        ),
        "HOST_MOVIES_PATH": ("/volume1/plex/movies", f"{media_root}/movies"),
        "HOST_TV_PATH": ("/volume1/plex/tv", f"{media_root}/tv"),
        "HOST_ANIME_TV_PATH": (
            "/volume1/plex/anime-tv",
            f"{media_root}/anime-tv",
        ),
        "HOST_SCENES_PATH": ("/volume1/plex/scenes", f"{media_root}/scenes"),
        "JELLYFIN_DATA_PATH": ("/volume1/jellyfin", media_root),
        "WHISPARR_DATA_PATH": ("/volume1/media/adult", media_root),
    }
    for variable, (source_default, preset_default) in preset_defaults.items():
        rendered = rendered.replace(
            f"${{{variable}:-{source_default}}}",
            f"${{{variable}:-{preset_default}}}",
        )
    rendered = rendered.rstrip() + "\n"
    if plan.preset.host_port_offset:
        # Offset only variables that publish a host port in the resolved chart.
        # Internal service ports and host-network services remain unchanged.
        compose = render_compose(catalog, plan)
        published_variables = set(
            re.findall(
                r"^\s*-\s+\$\{([A-Z][A-Z0-9_]*PORT)\}:",
                compose,
                flags=re.MULTILINE,
            )
        )
        remapped_ports: dict[str, str] = {}
        for variable in published_variables:
            assignment = re.compile(
                rf'^{re.escape(variable)}="\$\{{{re.escape(variable)}:-(\d+)\}}"$',
                flags=re.MULTILINE,
            )
            match = assignment.search(rendered)
            if not match:
                continue
            original_port = match.group(1)
            offset_port = str(int(original_port) + plan.preset.host_port_offset)
            if int(offset_port) > 65535:
                raise RenderError(
                    f"Preset '{plan.preset.id}' offsets {variable} beyond port 65535."
                )
            rendered = assignment.sub(
                f'{variable}="${{{variable}:-{offset_port}}}"',
                rendered,
                count=1,
            )
            remapped_ports[original_port] = offset_port
        for original_port, offset_port in remapped_ports.items():
            rendered = rendered.replace(
                f"host.or.ip:{original_port}",
                f"host.or.ip:{offset_port}",
            )
    existing = _existing_values(existing_path) if existing_path else {}
    if generate_secrets:
        rendered = _generate_first_run_secrets(rendered, existing)
    rendered = _preserve_values(rendered, existing)
    all_sources = [base_source] + [
        catalog.source_path(service.environment).read_text()
        for service in catalog.services.values()
    ]
    known_keys = set().union(*(_assignment_keys(source) for source in all_sources))
    return _preserve_inactive_values(rendered, existing, known_keys)


def _homepage_card(source: str, label: str) -> str:
    """Extract one Homepage card by its project-owned display label."""
    marker = f"    - {label}:\n"
    start = source.find(marker)
    if start < 0:
        raise RenderError(f"Homepage card '{label}' was not found.")
    end = len(source)
    for next_marker in ("\n    - ", "\n- "):
        candidate = source.find(next_marker, start + len(marker))
        if candidate >= 0:
            end = min(end, candidate)
    return source[start:end].strip("\n")


def _filter_calendar(card: str, selected: set[str]) -> str:
    """Remove calendar integrations whose backing services are unselected."""
    lines = []
    skip = False
    for line in card.splitlines():
        if line.startswith("            - type: "):
            integration = line.split(":", 1)[1].strip()
            skip = integration not in selected
        if not skip:
            lines.append(line)
    return "\n".join(lines)


def render_homepage_services(catalog: Catalog, plan: StackPlan) -> str:
    """Render Homepage groups and cards for selected integrations.

    Args:
        catalog: Validated catalog used to locate Homepage source fragments.
        plan: Resolved service selection controlling cards and calendar items.

    Returns:
        A complete Homepage ``services.yaml`` document.

    Raises:
        RenderError: If a required built-in card cannot be found.
        OSError: If a Homepage source fragment cannot be read.
    """
    homepage_root = catalog.source_path("services/homepage/config")
    source = (homepage_root / "services.base.yaml").read_text()
    source += (homepage_root / "services.footer.yaml").read_text()
    selected = set(plan.service_ids)
    include_plex_homepage = plan.preset.id == "plundarr" or "plex" in selected
    preamble = source[: source.find("- Media:")].rstrip()

    media_cards = []
    if include_plex_homepage:
        media_cards.append(_homepage_card(source, "Plex"))
    for service_id, label in (
        ("radarr", "Radarr"),
        ("sonarr", "Sonarr"),
        ("sonarr-anime", "Sonarr Anime"),
        ("bazarr", "Bazarr"),
        ("seerr", "Seerr"),
        ("jellyfin", "Jellyfin"),
    ):
        if service_id not in selected:
            continue
        if service_id in {"sonarr-anime", "jellyfin"}:
            fragment = homepage_root / "fragments" / f"{service_id}.yaml"
            media_cards.append(fragment.read_text().strip("\n"))
        else:
            media_cards.append(_homepage_card(source, label))

    data_cards = []
    if selected.intersection({"radarr", "sonarr"}):
        data_cards.append(_filter_calendar(_homepage_card(source, "Calendar"), selected))
    if include_plex_homepage:
        data_cards.append(_homepage_card(source, "Tautulli"))

    download_cards = []
    if "prowlarr" in selected:
        download_cards.append(_homepage_card(source, "Prowlarr"))
    for service_id, label in (
        ("qbittorrent", "qBittorrent"),
        ("sabnzbd", "SABnzbd"),
        ("nzbget", "NZBGet"),
    ):
        if service_id in selected:
            fragment = homepage_root / "fragments" / f"{service_id}.yaml"
            download_cards.append(fragment.read_text().strip("\n"))
    if "speedtest-tracker" in selected:
        download_cards.append(_homepage_card(source, "Speedtest Tracker"))

    groups = []
    for title, cards in (
        ("Media", media_cards),
        ("Data", data_cards),
        ("Downloads", download_cards),
    ):
        if cards:
            groups.append(f"- {title}:\n" + "\n\n".join(cards))
    body = "\n\n".join(groups) if groups else "[]"
    return preamble + "\n\n" + body + "\n"


def _atomic_write(path: Path, content: str, mode: int | None = None) -> None:
    """Replace one text file atomically with predictable permissions.

    Temporary files are created beside the destination so ``os.replace`` stays
    on one filesystem. Environment files default to owner-only permissions.
    """
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    temporary_path = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w") as temporary_file:
            temporary_file.write(content)
        file_mode = mode if mode is not None else (0o600 if path.name == ".env" else 0o644)
        temporary_path.chmod(file_mode)
        os.replace(temporary_path, path)
    finally:
        temporary_path.unlink(missing_ok=True)


def _seed_config_tree(source_root: Path, destination_root: Path) -> None:
    """Copy safe config seeds while preserving existing application state.

    Generated Homepage assembly fragments never leave the source tree. Existing
    application files win, while project-owned README files may be refreshed to
    keep generated guidance current.
    """
    if not source_root.is_dir():
        return

    excluded_names = {"services.base.yaml", "services.footer.yaml", "services.yaml"}
    for source_path in sorted(source_root.rglob("*")):
        relative_path = source_path.relative_to(source_root)
        if "fragments" in relative_path.parts or source_path.name in excluded_names:
            continue

        destination_path = destination_root / relative_path
        if source_path.is_dir():
            destination_path.mkdir(parents=True, exist_ok=True)
            continue

        destination_path.parent.mkdir(parents=True, exist_ok=True)
        if destination_path.exists() and source_path.name != "README.md":
            continue

        # README files are documentation owned by Maraudarr rather than mutable
        # application state, so regeneration may safely refresh their content.
        if source_path.name == "README.md":
            _atomic_write(
                destination_path,
                source_path.read_text(),
                source_path.stat().st_mode & 0o777,
            )
            continue

        shutil.copyfile(source_path, destination_path)
        destination_path.chmod(source_path.stat().st_mode & 0o777)


def write_config(catalog: Catalog, plan: StackPlan, output_dir: Path) -> Path:
    """Create selected config directories without replacing application state.

    Args:
        catalog: Validated catalog containing shared and service config seeds.
        plan: Resolved service selection controlling generated directories.
        output_dir: Plundarr project directory that owns ``config/``.

    Returns:
        Path to the generated or updated config root.

    Raises:
        RenderError: If a required Homepage card cannot be rendered.
        OSError: If directories or seed files cannot be created or copied.
    """
    config_path = output_dir / "config"
    config_path.mkdir(parents=True, exist_ok=True)
    _seed_config_tree(catalog.source_path("config"), config_path)

    for service in plan.services:
        _seed_config_tree(
            catalog.config_path(service),
            config_path / service.service,
        )

    if "homepage" in plan.service_ids:
        _atomic_write(
            config_path / "homepage" / "services.yaml",
            render_homepage_services(catalog, plan),
        )

    return config_path


def validate_compose(output_dir: Path) -> None:
    """Ask Docker Compose to validate a generated project pair.

    Args:
        output_dir: Directory containing ``docker-compose.yml`` and ``.env``.

    Raises:
        RenderError: If an installed Docker Compose command rejects the project.

    Note:
        Missing Docker Compose executables are tolerated so source-only
        environments can still render output. Any installed command that
        returns failure is treated as authoritative.
    """
    arguments = [
        "--env-file",
        str(output_dir / ".env"),
        "-f",
        str(output_dir / "docker-compose.yml"),
        "config",
        "--quiet",
    ]
    commands = (["docker", "compose", *arguments], ["docker-compose", *arguments])
    for command in commands:
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=False,
            )
        except FileNotFoundError:
            continue
        if result.returncode:
            message = result.stderr.strip() or result.stdout.strip()
            raise RenderError(
                f"Docker Compose rejected the generated stack: {message}"
            )
        return


def write_stack(
    catalog: Catalog,
    plan: StackPlan,
    output_dir: Path,
) -> tuple[Path, Path, Path]:
    """Generate, validate, and write a complete Plundarr project.

    Compose and environment artifacts are staged and validated before their
    public paths are atomically replaced. Config seeds are applied afterward
    using preservation rules appropriate for application-owned state.

    Args:
        catalog: Validated catalog providing templates and service sources.
        plan: Resolved service selection in deterministic generation order.
        output_dir: Directory that receives the generated Plundarr project.

    Returns:
        Paths to ``docker-compose.yml``, ``.env``, and the config directory.

    Raises:
        RenderError: If rendering requirements or Compose validation fail.
        OSError: If staging, writing, or replacing output files fails.
    """
    compose_path = output_dir / "docker-compose.yml"
    env_path = output_dir / ".env"
    example_env_path = output_dir / "example.env"
    compose = render_compose(catalog, plan)
    environment = render_environment(catalog, plan, env_path)
    example_environment = render_environment(
        catalog,
        plan,
        None,
        generate_secrets=False,
    )
    output_dir.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".maraudarr-build-", dir=output_dir) as staging:
        staging_dir = Path(staging)
        staged_compose = staging_dir / "docker-compose.yml"
        staged_env = staging_dir / ".env"
        staged_example_env = staging_dir / "example.env"
        _atomic_write(staged_compose, compose)
        _atomic_write(staged_env, environment)
        _atomic_write(staged_example_env, example_environment)
        validate_compose(staging_dir)
        os.replace(staged_compose, compose_path)
        os.replace(staged_env, env_path)
        os.replace(staged_example_env, example_env_path)

    config_path = write_config(catalog, plan, output_dir)
    return compose_path, env_path, config_path
