provider "azurerm" {
    features {}
}

provider "random" {
}

provider "kubernetes" {
    host = azurerm_kubernetes_cluster.stateful.kube_config[0].host
    client_certificate = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].client_certificate)
    client_key = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].cluster_ca_certificate)
}

provider "helm" {

    kubernetes {
        host = azurerm_kubernetes_cluster.stateful.kube_config[0].host
        client_certificate = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].client_certificate)
        client_key = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].client_key)
        cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.stateful.kube_config[0].cluster_ca_certificate)  
    }
}

# Resource Group
resource "azurerm_resource_group" "stateful" {
    location = var.location
    name = var.resource_group
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
    address_space = [var.address_space]
    location = azurerm_resource_group.stateful.location
    name = var.virtual_network_name
    resource_group_name = azurerm_resource_group.stateful.name
}

# Subnet
resource "azurerm_subnet" "subnet_aks" {
    address_prefixes = [var.subnet_aks_prefix]
    name = "${var.prefix}-subnet-aks"
    resource_group_name = azurerm_resource_group.stateful.name
    virtual_network_name = azurerm_virtual_network.vnet.name
}

# Security Group
resource "azurerm_network_security_group" "stateful" {
    location = var.location
    name = "${var.prefix}-sg"
    resource_group_name = azurerm_resource_group.stateful.name

    security_rule {
        name                       = "HTTPS"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = var.source_network
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 101
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = var.source_network
        destination_address_prefix = "*"
    }
}

# Associate security group with subnet

resource "azurerm_subnet_network_security_group_association" "stateful" {
    subnet_id = azurerm_subnet.subnet_aks.id
    network_security_group_id = azurerm_network_security_group.stateful.id
}

# Public IP
resource "azurerm_public_ip" "stateful" {
    allocation_method       = "Static"
    domain_name_label       = var.hostname
    location                = var.location
    name                    = "${var.prefix}-ip"
    resource_group_name     = azurerm_kubernetes_cluster.stateful.node_resource_group
    sku                     = "Standard"
}

# MySQL db password

resource "random_string" "mysql_password" {
    length = 16
    special = false
    upper = true
    lower = true
    numeric = true
}

# MySQL - database server

resource "azurerm_mysql_server" "stateful" {

    administrator_login           = "mysqladmin"
    administrator_login_password  = random_string.mysql_password.result

    sku_name    = "B_Gen5_1"
    storage_mb  = 5120
    version     = "5.7"

    location                = azurerm_resource_group.stateful.location
    name                    = "${var.prefix}-mysql"
    resource_group_name     = azurerm_resource_group.stateful.name 

    auto_grow_enabled                 = true
    backup_retention_days             = 7
    geo_redundant_backup_enabled      = false
    public_network_access_enabled     = true
    ssl_enforcement_enabled           = false
}

# MySQL - MySQL database

resource "azurerm_mysql_database" "stateful" {
  charset             = "UTF8"
  collation           = "utf8_unicode_ci"
  name                = var.prefix
  resource_group_name = azurerm_resource_group.stateful.name
  server_name         = azurerm_mysql_server.stateful.name
}

# MySQL Firewall - allows access from Azure Services (e.g. AKS)

resource "azurerm_mysql_firewall_rule" "stateful" {
    name                    = "stateful-aks-access"
    resource_group_name     = azurerm_resource_group.stateful.name
    server_name             = azurerm_mysql_server.stateful.name
    start_ip_address    = "0.0.0.0"
    end_ip_address      = "0.0.0.0"
}