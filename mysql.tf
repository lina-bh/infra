resource "random_password" "mysql" {
  length = 32
}

resource "oci_mysql_mysql_db_system" "mysql" {
  compartment_id      = oci_core_subnet.sn.compartment_id
  availability_domain = local.availability_domains["3"]

  display_name   = "mysql"
  hostname_label = "mysql"
  shape_name     = "MySQL.Free"
  subnet_id      = oci_core_subnet.sn.id
  admin_username = "admin"
  admin_password = random_password.mysql.result

  data_storage {
    is_auto_expand_storage_enabled = false
  }

  data_storage_size_in_gb = 50

  database_console {
    status = "DISABLED"
  }

  database_management = "DISABLED"
}
