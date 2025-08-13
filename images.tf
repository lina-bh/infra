resource "oci_objectstorage_bucket" "images" {
  compartment_id = data.oci_objectstorage_namespace.ns.compartment_id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "images"
  auto_tiering   = "InfrequentAccess"
}

resource "oci_core_image" "alpine" {
  for_each = local.archs

  compartment_id = oci_objectstorage_bucket.images.compartment_id

  display_name = var.alpine_images[each.key]

  image_source_details {
    source_type       = "objectStorageTuple"
    namespace_name    = oci_objectstorage_bucket.images.namespace
    bucket_name       = oci_objectstorage_bucket.images.name
    object_name       = var.alpine_images[each.key]
    source_image_type = "QCOW2"
  }

  launch_mode = "PARAVIRTUALIZED"
}

resource "oci_core_shape_management" "alpine" {
  for_each = local.archs

  compartment_id = oci_core_image.alpine[each.key].compartment_id

  image_id   = oci_core_image.alpine[each.key].id
  shape_name = local.shape[each.key]
}

resource "oci_core_compute_image_capability_schema" "alpine" {
  for_each = local.archs

  compartment_id = oci_core_image.alpine[each.key].compartment_id
  image_id       = oci_core_image.alpine[each.key].id

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
