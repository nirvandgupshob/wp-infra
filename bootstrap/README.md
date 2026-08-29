# bootstrap — общие долгоживущие ресурсы

То, что переживает окружения и не должно попадать под `terraform destroy`. Применяется **один раз и вручную**: пайплайну нужен уже существующий бакет со state, чтобы вообще начать работу.

## Что создаётся

| Ресурс | Зачем |
|---|---|
| S3-бакет `wp-tfstate-<account-id>` | хранит `staging/terraform.tfstate` и `production/terraform.tfstate` |
| KMS-ключ с ротацией | шифрование state; право расшифровать управляется отдельно от доступа к бакету |
| Репозиторий ECR `wp/wordpress` | общий на оба окружения — промоушен переносит дайджест, а не копирует образ |
| OIDC-провайдер GitHub и пять ролей | доступ пайплайнов к AWS без статических ключей |
| CloudTrail `wp-audit` и бакет под него | журнал вызовов API всех регионов с проверкой целостности |

У бакетов включены versioning, блокировка публичного доступа, политика `DenyInsecureTransport` и правила жизненного цикла. На обоих стоит `prevent_destroy`.

Блокировка параллельных запусков — нативная через S3 (`use_lockfile = true`, Terraform ≥ 1.10).

Зона Route53 сюда не входит: она создана вне Terraform и подключается data-источником, потому что при пересоздании получает новые nameservers и ломает делегирование у регистратора.

## Первое применение

Бакета ещё не существует, поэтому первый запуск идёт с локальным state.

```bash
cd wp-infra/bootstrap
terraform init
terraform apply
```

Затем state переносится внутрь созданного бакета: раскомментировать блок `backend "s3"` в `versions.tf`, подставив значения из `terraform output backend_config`, и выполнить

```bash
terraform init -migrate-state
```

После подтверждения переноса локальный `terraform.tfstate` можно удалить — состояние bootstrap живёт в S3 вместе с остальными.

## Роли для GitHub

Доверие выписано в неизменяемом формате субъекта: `repo:<owner>@<owner-id>/<repo>@<repo-id>:environment:<env>`. Числовые идентификаторы GitHub не переиспользует, поэтому переименованный или пересозданный репозиторий роль не унаследует. Значения задаются переменными `github_owner`, `infra_repository`, `app_repository`.

Узнать идентификаторы:

```bash
gh api users/<owner> --jq .id
gh api repos/<owner>/<repo> --jq .id
```

## Проверка

```bash
aws s3api get-public-access-block --bucket $(terraform output -raw state_bucket)
aws ecr describe-repositories --repository-names wp/wordpress \
  --query 'repositories[0].imageTagMutability'
aws cloudtrail get-trail-status --name wp-audit --query IsLogging
terraform plan -detailed-exitcode
```
