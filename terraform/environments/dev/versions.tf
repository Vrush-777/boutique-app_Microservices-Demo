terraform {

  required_version = ">=1.5.0"

  backend "azurerm" {

    resource_group_name = "rg-terraform-state"

    storage_account_name = "vrushterraformstate777"

    container_name = "tfstate"

    key = "dev.terraform.tfstate"

  }


  required_providers {

    azurerm = {

      source = "hashicorp/azurerm"

      version = "~>4.0"

    }

  }

}