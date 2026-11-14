# Maintain your Plundarr stack

Run direct Compose commands from the generated `dist/<preset>/` directory. Make commands run from a repository checkout and take `PRESET=YOUR-PRESET`; omit that argument for default Plundarr. Keep `.env`, configuration, VPN files, and logs containing private values private.

## Stop and restart

Stop the project and remove its containers and network:

```sh
docker compose down
```

Application volumes, bind-mounted data, and images remain. Start again with `docker compose up --detach`. From a checkout, the equivalent shortcuts are `make down` and `make up`.

## Back up before changes

Use application-consistent exports before updates or resets. Stop affected writers before copying configuration files. A live database file copy is not a reliable application backup. Include the private `.env`, encryption keys, external libraries/configuration, and named-volume database exports in your recovery set, and verify an off-host copy.

The [generated configuration notes](https://github.com/scottgigawatt/plundarr/blob/main/docker/config/README.md#back-up-or-reset-the-hold-) explain coverage and recovery boundaries. From a checkout, `make backup PRESET=YOUR-PRESET` archives the host config tree only; it does not export named volumes or external state.

## Update application images

After verifying backups and reviewing the selected images' requirements, update the generated project:

```sh
docker compose pull
docker compose up --detach
```

Check status and the application interfaces afterward. Recreate the complete VPN/download group when changing Gluetun's network namespace. Privateerr's automatic recovery refreshes the VPN connection without restarting the downloader; see [VPN operation](project-guides/vpn.md).

Watchtower can automate eligible updates across the Docker host. Review its [scope and exclusions](https://github.com/scottgigawatt/plundarr/blob/main/docker/services/watchtower/README.md); run only one persistent instance per host.

## Regenerate a deployment

Regeneration updates Compose files and missing seeds. Existing environment values and application state survive; Homepage's generated service cards are refreshed. Review any manual card edits before regeneration.

1. Verify backups and record the full intended preset/service selection.
2. Run the [published generator command](https://scottgigawatt.github.io/plundarr/setup/#generate-a-deployment) from the same output directory and select those services again. From a checkout, use `make pull-image` then `make configure` or `make generate` with the full selection.
3. Review `.env` for selected services and required host values. Preserved values do not reselect services.
4. From the generated directory, validate and recreate the project:

    ```sh
    docker compose config --quiet
    docker compose up --detach --pull always --remove-orphans
    docker compose ps
    ```

Generation itself leaves omitted running containers alone. The `--remove-orphans` startup option removes containers omitted from the new project; confirm that selection before running it. Pulling Maraudarr alone does not update running application containers.

## Choose a cleanup operation

These Make commands operate from the checkout on the selected preset:

| Command | Removes | Preserves |
| --- | --- | --- |
| `make clean-artifacts` | Disposable developer files | Deployments and all Docker resources |
| `make down` | Project containers and networks | Images, volumes, configuration, backups |
| `make remove-stack` | Selected-stack Docker resources, Maraudarr resources, eligible images, and scoped build cache | Deployment files, all config/VPN state, application volumes, backups |
| `make delete-config` | Selected host config tree | Named volumes and paths outside that tree |

> [!CAUTION]
> `make remove-stack` interrupts services and can require image downloads before restart. `make delete-config` deletes configuration, databases, and exports stored inside the selected config tree. Stop affected services and verify backups before destructive cleanup.

`make remove-stack` leaves saved VPN settings intact and never restores test examples. Test-only reset commands belong to isolated disposable tests; read the [testing guide](project-guides/testing.md) before using them.
