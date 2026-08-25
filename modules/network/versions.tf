terraform {
  required_version = "~> 1.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.61"
    }
  }

  # Блока provider здесь нет намеренно: модуль не настраивает провайдера,
  # а получает его от вызывающего кода (envs/staging, envs/production).
  # Иначе модуль нельзя было бы использовать в двух окружениях сразу.
}
