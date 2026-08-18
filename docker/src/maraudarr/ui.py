#
# Copyright 2025-2026 Scott Gigawatt
#
# Licensed under the Apache License, Version 2.0.
#
# ui.py: Present Maraudarr's interactive and plain terminal experiences.
#

"""Professional, lightly pirate-themed terminal presentation for Maraudarr."""

from __future__ import annotations

import os
import sys
from collections import defaultdict

from maraudarr.models import Preset, Service, StackPlan

try:
    import questionary
    from questionary import Choice, Style
    from rich import box
    from rich.console import Console
    from rich.panel import Panel
    from rich.table import Table

    RICH_AVAILABLE = True
except ImportError:  # pragma: no cover - dependency-free developer execution
    RICH_AVAILABLE = False


PIRATE_STYLE = None
if RICH_AVAILABLE:
    PIRATE_STYLE = Style(
        [
            ("qmark", "fg:#f2c14e bold"),
            ("question", "bold"),
            ("answer", "fg:#52b788 bold"),
            ("pointer", "fg:#f2c14e bold"),
            ("highlighted", "fg:#f2c14e bold"),
            ("selected", "fg:#52b788"),
            ("separator", "fg:#6c757d"),
            ("instruction", "fg:#8d99ae"),
            ("text", ""),
            ("disabled", "fg:#6c757d italic"),
        ]
    )


class UserCancelled(RuntimeError):
    """Represent an intentional cancellation rather than a generator failure."""


class UI:
    """Render Maraudarr output consistently in rich and plain terminals.

    Rich presentation is used only when optional dependencies are available,
    styled output is allowed, and the caller did not request plain mode.

    Attributes:
        plain: Whether output uses dependency-free text presentation.
        console: Rich console instance, or ``None`` in plain mode.
    """

    def __init__(self, plain: bool = False) -> None:
        """Create a terminal presenter.

        Args:
            plain: Force dependency-free output even when Rich is available.
                The ``NO_COLOR`` environment variable also enables this mode.
        """
        self.plain = plain or not RICH_AVAILABLE or bool(os.environ.get("NO_COLOR"))
        self.console = None if self.plain else Console()

    def welcome(self) -> None:
        """Display Maraudarr's purpose before listing available choices."""
        message = (
            "[bold]Choose a voyage, load the services, and chart one reusable "
            "Plundarr Docker Compose stack.[/bold]"
        )
        if self.console:
            self.console.print(
                Panel(
                    message,
                    title="🏴‍☠️  Maraudarr",
                    border_style="#f2c14e",
                    padding=(1, 3),
                )
            )
        else:
            print("Maraudarr")
            print("Generate one reusable Plundarr Docker Compose stack.\n")

    def show_presets(
        self,
        presets: list[Preset],
        service_lookup: dict[str, Service],
    ) -> None:
        """List presets with their exact default services.

        Args:
            presets: Presets to display in caller-supplied order.
            service_lookup: Service metadata keyed by catalog identifier.
        """
        if self.console:
            table = Table(
                title="🗺️  Available Voyages",
                box=box.ROUNDED,
                header_style="bold",
            )
            table.add_column("Preset", style="#f2c14e", no_wrap=True)
            table.add_column("Purpose")
            table.add_column("Default cargo")
            for preset in presets:
                ordered_services = sorted(
                    (service_lookup[item] for item in preset.services),
                    key=lambda service: service.order,
                )
                cargo = ", ".join(service.title for service in ordered_services)
                table.add_row(preset.title, preset.description, cargo or "Choose your own")
            self.console.print(table)
            return

        for preset in presets:
            ordered_services = sorted(
                (service_lookup[item] for item in preset.services),
                key=lambda service: service.order,
            )
            cargo = ", ".join(service.title for service in ordered_services)
            print(f"{preset.id}: {preset.description}\n  Services: {cargo or 'Choose your own'}")

    def choose_preset(self, presets: list[Preset]) -> str:
        """Prompt for one preset in an interactive terminal.

        Args:
            presets: Ordered choices presented to the user.

        Returns:
            Stable identifier of the selected preset.

        Raises:
            UserCancelled: If no interactive terminal is available or the user
                exits without choosing a preset.
        """
        if self.plain or not sys.stdin.isatty():
            raise UserCancelled("Interactive configuration requires a terminal.")
        answer = questionary.select(
            "🗺️  Choose a voyage",
            choices=[Choice(preset.title, preset.id) for preset in presets],
            style=PIRATE_STYLE,
            use_shortcuts=True,
        ).ask()
        if answer is None:
            raise UserCancelled("Voyage cancelled before leaving port.")
        return str(answer)

    def show_service_choices(self, services: list[Service]) -> None:
        """Explain selectable services before interactive checkbox prompts.

        Args:
            services: Selectable services in desired presentation order.
        """
        if self.console:
            table = Table(
                title="🧩 Available Cargo",
                box=box.ROUNDED,
                header_style="bold",
            )
            table.add_column("Category", style="#f2c14e", no_wrap=True)
            table.add_column("Service", style="bold", no_wrap=True)
            table.add_column("What it adds")
            for service in services:
                table.add_row(service.category, service.title, service.description)
            self.console.print(table)
            return

        print("Available services:")
        for service in services:
            print(f"  {service.id:<18} {service.description}")

    def choose_services(
        self,
        services: list[Service],
        selected: set[str],
    ) -> set[str]:
        """Collect service choices grouped by category.

        Args:
            services: Selectable services in category and presentation order.
            selected: Service IDs checked when each category prompt opens.

        Returns:
            Service IDs checked across every category.

        Raises:
            UserCancelled: If no interactive terminal is available or the user
                exits any category prompt.
        """
        if self.plain or not sys.stdin.isatty():
            raise UserCancelled("Interactive configuration requires a terminal.")

        grouped_services: dict[str, list[Service]] = defaultdict(list)
        for service in services:
            grouped_services[service.category].append(service)

        chosen: set[str] = set()
        for category, category_services in grouped_services.items():
            answers = questionary.checkbox(
                f"🧩 {category}",
                choices=[
                    Choice(
                        service.title,
                        service.id,
                        checked=service.id in selected,
                    )
                    for service in category_services
                ],
                style=PIRATE_STYLE,
                instruction="Space selects cargo; Enter continues",
            ).ask()
            if answers is None:
                raise UserCancelled("Voyage cancelled while loading cargo.")
            chosen.update(str(answer) for answer in answers)
        return chosen

    def show_plan(self, plan: StackPlan) -> None:
        """Present the resolved service manifest before writing files.

        Args:
            plan: Fully resolved stack plan, including automatic dependencies.
        """
        if self.console:
            summary = Table.grid(padding=(0, 2))
            summary.add_column(style="bold")
            summary.add_column()
            summary.add_row("Preset", plan.preset.title)
            summary.add_row("Services", str(len(plan.services)))
            summary.add_row(
                "Cargo",
                ", ".join(service.title for service in plan.services),
            )
            self.console.print(
                Panel(summary, title="⚓ Stack Manifest", border_style="#2a9d8f")
            )
            if plan.auto_added:
                self.console.print(
                    "[bold #f2c14e]Dependency check:[/] "
                    + ", ".join(plan.auto_added)
                    + " joined the fleet automatically."
                )
            return

        print(f"Preset: {plan.preset.title}")
        print("Services: " + ", ".join(service.id for service in plan.services))

    def confirm(self) -> bool:
        """Confirm a plan when attached to an interactive terminal.

        Returns:
            ``True`` for a confirmed prompt or any non-interactive plain run.

        Raises:
            UserCancelled: If the user dismisses the confirmation prompt.
        """
        if self.plain or not sys.stdin.isatty():
            return True
        answer = questionary.confirm(
            "⚒️  Build this stack?",
            default=True,
            style=PIRATE_STYLE,
        ).ask()
        if answer is None:
            raise UserCancelled("Voyage cancelled before the stack was built.")
        return bool(answer)

    def progress(self, message: str) -> None:
        """Print one generation progress message.

        Args:
            message: User-facing status text to display unchanged.
        """
        if self.console:
            self.console.print(message)
        else:
            print(message)

    def success(
        self,
        plan: StackPlan,
        compose_path: str,
        env_path: str,
        config_path: str,
    ) -> None:
        """Report generated artifacts and context-aware launch instructions.

        Args:
            plan: Generated plan used to select relevant follow-up steps.
            compose_path: Display path to the generated Compose chart.
            env_path: Display path to the generated environment file.
            config_path: Display path to the generated config root.
        """
        selected = set(plan.service_ids)
        steps = []
        if "privateerr" in selected:
            steps.append("Set PIA_USER and PIA_PASS in .env.")
        if selected.intersection(
            {
                "bazarr",
                "duplicati",
                "jellyfin",
                "nzbget",
                "plex",
                "qbittorrent",
                "radarr",
                "sabnzbd",
                "sonarr",
                "sonarr-anime",
                "whisparr",
            }
        ):
            steps.append("Check download, media, and config paths in .env.")
        steps.append("Start the stack with make up.")

        if self.console:
            table = Table.grid(padding=(0, 2))
            table.add_column(style="bold")
            table.add_column()
            table.add_row("Compose chart", compose_path)
            table.add_row("Environment", env_path)
            table.add_row("Config cargo", config_path)
            table.add_row("Services", str(len(plan.services)))
            self.console.print(
                Panel(
                    table,
                    title=f"✅ {plan.preset.title} Ready to Sail",
                    border_style="#52b788",
                )
            )
            self.console.print("\n[bold]Before launch:[/]")
            for number, step in enumerate(steps, start=1):
                self.console.print(f"  {number}. {step}")
            return

        print(
            f"{plan.preset.title} ready: "
            f"{compose_path}, {env_path}, and {config_path}"
        )
        for number, step in enumerate(steps, start=1):
            print(f"{number}. {step}")

    def error(self, message: str, fix: str | None = None) -> None:
        """Display a generator failure and optional corrective action.

        Args:
            message: Concrete failure explanation.
            fix: Optional next action that may correct the failure.
        """
        body = message
        if fix:
            body += f"\n\n[bold]Fix:[/] {fix}"
        if self.console:
            self.console.print(
                Panel(body, title="☠️ Maraudarr could not finish", border_style="red")
            )
        else:
            print(f"Error: {message}", file=sys.stderr)
            if fix:
                print(f"Fix: {fix}", file=sys.stderr)

    def cancelled(self, message: str) -> None:
        """Display an intentional cancellation without reporting failure.

        Args:
            message: Cancellation reason to present to the user.
        """
        if self.console:
            self.console.print(
                Panel(message, title="⚓ Voyage Cancelled", border_style="#f2c14e")
            )
        else:
            print(message)
