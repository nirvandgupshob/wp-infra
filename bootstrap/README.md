# bootstrap — хранилище Terraform state

Создаёт S3-бакет, в котором лежит состояние всех окружений, и KMS-ключ для его шифрования.

Применяется **один раз и вручную**. В CI/CD не участвует: пайплайну нужен уже существующий бакет, чтобы вообще начать работу.

## Что создаётся

| Ресурс | Зачем |
|---|---|
| S3-бакет `wp-tfstate-<account-id>` | хранит `staging/terraform.tfstate` и `production/terraform.tfstate` |
| Versioning | откат к предыдущей версии, если state испорчен |
| KMS-ключ с ротацией | шифрование state; доступ к расшифровке управляется отдельно от доступа к бакету |
| Public access block | state не может стать публичным даже по ошибке |
| Bucket policy `DenyInsecureTransport` | запрет обращений не по TLS |
| Lifecycle rule | старые версии state удаляются через 30 дней |

Блокировка параллельных запусков — нативная через S3 (`use_lockfile = true`, Terraform ≥ 1.10).

## Порядок применения

Бакета ещё не существует, поэтому первый запуск идёт с локальным state.

```bash
cd wp-infra/bootstrap
terraform init
terraform plan
terraform apply
```

Затем state переносится внутрь только что созданного бакета. Раскомментируйте блок `backend "s3"` в `versions.tf`, подставив значения из вывода `terraform output backend_config`, и выполните:

```bash
terraform init -migrate-state
```

Terraform спросит подтверждение переноса — ответить `yes`. После этого локальный `terraform.tfstate` можно удалить: состояние живёт в S3, включая состояние самого bootstrap.

## Проверка

```bash
aws s3api get-bucket-versioning --bucket $(terraform output -raw state_bucket)
aws s3api get-public-access-block --bucket $(terraform output -raw state_bucket)
aws s3 ls s3://$(terraform output -raw state_bucket)/ --recursive
```
