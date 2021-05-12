# appstore

![Version: 0.1.30](https://img.shields.io/badge/Version-0.1.30-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.20](https://img.shields.io/badge/AppVersion-1.0.20-informational?style=flat-square)

A Helm chart for Kubernetes

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| ACCOUNT_DEFAULT_HTTP_PROTOCOL | string | `"http"` | Choose http or https for the protocol that is used by external users to access the appstore web service. |
| affinity | object | `{}` |  |
| ambassador.flag | bool | `true` | register appstore with ambassador flag: <True or False> |
| appStorage.claimName | string | `nil` |  |
| appStorage.existingClaim | bool | `false` |  |
| appStorage.storageClass | string | `nil` |  |
| appStorage.storageSize | string | `"2Gi"` |  |
| apps.DICOMGH_GOOGLE_CLIENT_ID | string | `""` |  |
| appstoreEntrypointArgs | string | `"make appstore.start brand="` | Allow for a custom entrypoint command via the values file.  The brand is set via the djangoSettings value, therefor 'brand=' needs to be at the end of this command. |
| createHomeDirs | bool | `true` | Create Home directories for users |
| db.name | string | `"appstore"` |  |
| django.ALLOW_DJANGO_LOGIN | string | `""` | show Django log in fields (true | false) |
| django.ALLOW_SAML_LOGIN | string | `""` | show SAML log in fields (true | false) |
| django.APPSTORE_DJANGO_PASSWORD | string | `""` |  |
| django.APPSTORE_DJANGO_USERNAME | string | `"admin"` |  |
| django.AUTHORIZED_USERS | string | `""` | user emails for oauth providers |
| django.DOCKSTORE_APPS_BRANCH | string | `"master"` | Defaults to "master". Specify "develop" to switch. |
| django.EMAIL_HOST_PASSWORD | string | `""` | password of account to use for outgoing emails |
| django.EMAIL_HOST_USER | string | `""` | email of account to use for outgoing emails |
| django.IMAGE_DOWNLOAD_URL | string | `""` | Specify URL to use for the "Image Download" link on the top part of website. |
| django.REMOVE_AUTHORIZED_USERS | string | `""` | user emails to remove from an already-existing database |
| django.SESSION_IDLE_TIMEOUT | int | `3600` | idle timeout for user web session |
| django.WHITELIST_REDIRECT | string | `"true"` | redirect unauthorized users of return a 403 |
| django.oauth.GITHUB_CLIENT_ID | string | `""` |  |
| django.oauth.GITHUB_KEY | string | `""` |  |
| django.oauth.GITHUB_NAME | string | `""` |  |
| django.oauth.GITHUB_SECRET | string | `""` |  |
| django.oauth.GITHUB_SITES | string | `""` |  |
| django.oauth.GOOGLE_CLIENT_ID | string | `""` |  |
| django.oauth.GOOGLE_KEY | string | `""` |  |
| django.oauth.GOOGLE_NAME | string | `""` |  |
| django.oauth.GOOGLE_SECRET | string | `""` |  |
| django.oauth.GOOGLE_SITES | string | `""` |  |
| django.oauth.OAUTH_PROVIDERS | string | `""` | oauth providers separated by commas (google, github) |
| django.saml2auth.ASSERTION_URL | string | `""` |  |
| django.saml2auth.ENTITY_ID | string | `""` |  |
| djangoSettings | string | `"cat"` | set the theme for appstore (cat, braini, restartr, scidas) |
| extraEnv | object | `{}` |  |
| fullnameOverride | string | `""` |  |
| global.stdnfsPvc | string | `"stdnfs"` | the name of the PVC to use for user's files |
| image.pullPolicy | string | `"IfNotPresent"` | pull policy |
| image.repository | string | `"helxplatform/appstore"` | repository where image is located |
| image.tag | string | `"develop-v1.1.77"` |  |
| imagePullSecrets | list | `[]` | credentials for a private repo |
| irods.BRAINI_RODS | string | `""` |  |
| irods.IROD_COLLECTIONS | string | `""` |  |
| irods.IROD_ZONE | string | `""` |  |
| irods.NRC_MICROSCOPY_IRODS | string | `""` |  |
| irods.RODS_PASSWORD | string | `""` |  |
| irods.RODS_USERNAME | string | `""` |  |
| irods.enabled | bool | `false` | enable irods support (true | false) |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| oauth.claimName | string | `"appstore-oauth-pvc"` |  |
| oauth.existingClaim | bool | `false` |  |
| oauth.storageClass | string | `nil` |  |
| parent_dir | string | `"/home"` | directory that will be used to mount user's home directories in |
| podAnnotations | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"400m"` |  |
| resources.limits.memory | string | `"625Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"300Mi"` |  |
| runAsRoot | bool | `true` |  |
| service.name | string | `"http"` |  |
| service.port | int | `80` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.create | bool | `true` | specifies whether a service account should be created |
| serviceAccount.name | string | `nil` | The name of the service account to use. If not set and create is true, a name is generated using the fullname template |
| shared_dir | string | `"shared"` | name of directory to use for shared data |
| subpath_dir | string | `nil` | Name of directory to use for a user's home directory.  If null then the user's username will be used. |
| tolerations | list | `[]` |  |
| useSparkServiceAccount | bool | `true` | Set to true, when using blackbalsam. |
| userStorage.createPVC | bool | `false` | Create a PVC for user's files.  If false then the PVC needs to be created outside of the appstore chart. |
| userStorage.nfs.createPV | bool | `false` |  |
| userStorage.nfs.path | string | `nil` |  |
| userStorage.nfs.server | string | `nil` |  |
| userStorage.storageClass | string | `nil` |  |
| userStorage.storageSize | string | `"10Gi"` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.5.0](https://github.com/norwoodj/helm-docs/releases/v1.5.0)
