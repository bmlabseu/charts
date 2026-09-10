# ClassicPress

[ClassicPress](https://www.classicpress.net) is a lightweight, stable CMS
forked from WordPress 4.9, without the block editor.

## Install

```sh
helm repo add bmlabs https://bmlabseu.github.io/charts
helm install my-site bmlabs/classicpress
```

This deploys ClassicPress with a bundled single-replica MariaDB. Open the
service and complete the ClassicPress installer to create the admin account.

## Production notes

- Point the chart at a managed database and turn off the bundled one:

  ```yaml
  mariadb:
    enabled: false
  database:
    host: mysql.example.com
    name: classicpress
    user: classicpress
    existingSecret: classicpress-db
    existingSecretPasswordKey: password
  ```

- The bundled MariaDB is a single StatefulSet with no backups or replication.
  It is fine for small sites, not for anything that must survive a node loss.
- `/var/www/html` holds the ClassicPress core, plugins, themes and uploads. With
  the default `ReadWriteOnce` volume, keep `replicaCount: 1`. Scaling out
  requires a `ReadWriteMany` storage class.
- Secret keys and salts are generated on first install and preserved across
  upgrades. Supply your own with `classicpress.existingSecret`, using the keys
  `AUTH_KEY`, `SECURE_AUTH_KEY`, `LOGGED_IN_KEY`, `NONCE_KEY`, `AUTH_SALT`,
  `SECURE_AUTH_SALT`, `LOGGED_IN_SALT`, `NONCE_SALT`.
- Apache in the upstream image starts as root and drops to `www-data`, so the
  container cannot run as non-root. All capabilities except those Apache needs
  to drop privileges are removed.

## Versioning

Upstream publishes rolling tags (`php8.3-apache`) rather than versioned ones.
The chart's `appVersion` tracks the ClassicPress version baked into those
images, and is updated automatically. Pin an exact image with `image.digest`
if you need reproducible rollouts.

## Values

### Image

| Key | Default | Description |
| --- | --- | --- |
| `image.repository` | `docker.io/classicpress/classicpress` | Image repository |
| `image.tag` | `php8.3-apache` | Image tag, selecting the PHP version |
| `image.digest` | `""` | Pin to a digest, overriding the tag |
| `image.pullPolicy` | `IfNotPresent` | Image pull policy |
| `imagePullSecrets` | `[]` | Pull secrets for private registries |

### ClassicPress

| Key | Default | Description |
| --- | --- | --- |
| `classicpress.tablePrefix` | `cp_` | Database table prefix |
| `classicpress.debug` | `false` | Enable `WP_DEBUG` |
| `classicpress.configExtra` | `""` | PHP appended to `wp-config.php` |
| `classicpress.existingSecret` | `""` | Secret holding the keys and salts |

### Database

| Key | Default | Description |
| --- | --- | --- |
| `database.host` | `""` | External host; defaults to the bundled MariaDB |
| `database.port` | `3306` | Database port |
| `database.name` | `classicpress` | Database name |
| `database.user` | `classicpress` | Database user |
| `database.password` | `""` | Password; generated when empty |
| `database.existingSecret` | `""` | Secret holding the password |
| `database.existingSecretPasswordKey` | `password` | Key within that secret |
| `database.charset` | `utf8mb4` | Connection charset |
| `database.collate` | `""` | Connection collation |

### Bundled MariaDB

| Key | Default | Description |
| --- | --- | --- |
| `mariadb.enabled` | `true` | Deploy a MariaDB StatefulSet |
| `mariadb.image.repository` | `docker.io/mariadb` | Image repository |
| `mariadb.image.tag` | `11.8.9` | Image tag |
| `mariadb.image.digest` | `""` | Pin to a digest, overriding the tag |
| `mariadb.rootPassword` | `""` | Root password; generated when empty |
| `mariadb.persistence.enabled` | `true` | Request a volume for `/var/lib/mysql` |
| `mariadb.persistence.storageClass` | `""` | Storage class |
| `mariadb.persistence.size` | `8Gi` | Volume size |
| `mariadb.persistence.existingClaim` | `""` | Use an existing claim |
| `mariadb.resources` | requests 100m/256Mi | Resource requests and limits |

### Storage

| Key | Default | Description |
| --- | --- | --- |
| `persistence.enabled` | `true` | Request a volume for `/var/www/html` |
| `persistence.storageClass` | `""` | Storage class |
| `persistence.accessModes` | `[ReadWriteOnce]` | Access modes |
| `persistence.size` | `10Gi` | Volume size |
| `persistence.existingClaim` | `""` | Use an existing claim |
| `persistence.subPath` | `""` | Subdirectory of the volume to serve |

The chart's own claim carries `helm.sh/resource-policy: keep`, so uninstalling
the release leaves your content in place.

### Networking

| Key | Default | Description |
| --- | --- | --- |
| `service.type` | `ClusterIP` | Service type |
| `service.port` | `80` | Service port |
| `service.annotations` | `{}` | Service annotations |
| `ingress.enabled` | `false` | Create an Ingress |
| `ingress.className` | `""` | Ingress class |
| `ingress.annotations` | `{}` | Ingress annotations |
| `ingress.hosts` | `classicpress.local` | Hosts and paths |
| `ingress.tls` | `[]` | TLS configuration |

### Workload

| Key | Default | Description |
| --- | --- | --- |
| `replicaCount` | `1` | Number of replicas |
| `updateStrategy` | `Recreate` | Deployment strategy |
| `resources` | requests 100m/256Mi | Resource requests and limits |
| `podSecurityContext` | `fsGroup: 33` | Pod security context |
| `securityContext` | root, minimal capabilities | Container security context |
| `livenessProbe`, `readinessProbe`, `startupProbe` | HTTP on `/wp-login.php` | Probes; set to `{}` to disable |
| `autoscaling.enabled` | `false` | Create a HorizontalPodAutoscaler |
| `podDisruptionBudget.enabled` | `false` | Create a PodDisruptionBudget |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `extraEnv`, `extraEnvFrom` | `[]` | Additional environment |
| `extraVolumes`, `extraVolumeMounts` | `[]` | Additional volumes |
| `extraInitContainers` | `[]` | Additional init containers |
| `podAnnotations`, `podLabels`, `commonLabels` | `{}` | Extra metadata |
| `nodeSelector`, `tolerations`, `affinity`, `topologySpreadConstraints` | empty | Scheduling |

## Upgrading

Check the [ClassicPress release notes](https://github.com/ClassicPress/ClassicPress-release/releases)
before a major upgrade, and back up the database and `/var/www/html` first.
