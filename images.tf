variable "fedora_aarch64_qcow2_url" {
  type    = string
  default = "https://download.fedoraproject.org/pub/fedora/linux/releases/43/Cloud/aarch64/images/Fedora-Cloud-Base-Generic-43-1.6.aarch64.qcow2"
}

resource "oci_objectstorage_bucket" "images" {
  compartment_id = data.oci_objectstorage_namespace.ns.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "images"
  auto_tiering   = "InfrequentAccess"
}

resource "oci_objectstorage_object" "fedora_aarch64_qcow2" {
  namespace = oci_objectstorage_bucket.images.namespace
  bucket    = oci_objectstorage_bucket.images.name
  object    = basename(var.fedora_aarch64_qcow2_url)

  provisioner "local-exec" {
    command = "curl -fsSL '${var.fedora_aarch64_qcow2_url}' | oci os object put -ns ${self.namespace} -bn ${self.bucket} --name ${self.object} --file - --force"
  }
}


resource "oci_core_image" "fedora_aarch64" {
  compartment_id = oci_objectstorage_bucket.images.compartment_id

  display_name = oci_objectstorage_object.fedora_aarch64_qcow2.object

  image_source_details {
    source_type       = "objectStorageTuple"
    namespace_name    = oci_objectstorage_object.fedora_aarch64_qcow2.namespace
    bucket_name       = oci_objectstorage_object.fedora_aarch64_qcow2.bucket
    object_name       = oci_objectstorage_object.fedora_aarch64_qcow2.object
    source_image_type = "QCOW2"
  }

  launch_mode = "PARAVIRTUALIZED"
}

resource "oci_core_shape_management" "fedora_aarch64" {
  compartment_id = oci_core_image.fedora_aarch64.compartment_id
  image_id       = oci_core_image.fedora_aarch64.id

  shape_name = "VM.Standard.A1.Flex"
}

resource "oci_core_compute_image_capability_schema" "fedora_aarch64" {
  compartment_id = oci_core_image.fedora_aarch64.compartment_id
  image_id       = oci_core_image.fedora_aarch64.id

  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schemas_version.version.name

  schema_data = {
    "Compute.Firmware" = jsonencode(merge(
      jsondecode(data.oci_core_compute_global_image_capability_schemas_version.version.schema_data["Compute.Firmware"]),
      {
        descriptorType = "enumstring"
        values         = ["BIOS", "UEFI_64"]
        defaultValue   = "UEFI_64"
        source         = "IMAGE"
      }
    )),
    "Compute.SecureBoot" = jsonencode(merge(
      jsondecode(data.oci_core_compute_global_image_capability_schemas_version.version.schema_data["Compute.SecureBoot"]),
      {
        descriptorType = "boolean"
        defaultValue   = true
        source         = "IMAGE"
      }
    ))
  }
}

# insane.

data "oci_core_compute_global_image_capability_schemas" "schemas" {
}

data "oci_core_compute_global_image_capability_schema" "schema" {
  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.schemas.compute_global_image_capability_schemas[0].id
}

data "oci_core_compute_global_image_capability_schemas_versions" "versions" {
  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schema.schema.id
}

data "oci_core_compute_global_image_capability_schemas_version" "version" {
  compute_global_image_capability_schema_id = (
    data
    .oci_core_compute_global_image_capability_schemas_versions
    .versions
    .compute_global_image_capability_schema_versions[0]
    .compute_global_image_capability_schema_id
  )

  compute_global_image_capability_schema_version_name = (
    data.
    oci_core_compute_global_image_capability_schemas_versions.
    versions.
    compute_global_image_capability_schema_versions[0]
    .name
  )
}
