resource "random_password" "k3s_token" {
  length  = 18
  special = false
}
