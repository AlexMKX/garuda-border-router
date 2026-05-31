locals {
  _frr_lib = "${path.module}/../frr-sidecar/charts/frr-sidecar/templates"

  # Track template changes so the helm_release upgrades when the deployment
  # template or any consumed frr-sidecar library template changes (#51 pattern).
  template_checksum = sha256(join("", [
    filesha256("${path.module}/charts/border-router/templates/deployment.yaml"),
    filesha256("${path.module}/charts/border-router/templates/configmap-frr.yaml"),
    filesha256("${path.module}/image/entrypoint.sh"),
    filesha256("${local._frr_lib}/_container.tpl"),
    filesha256("${local._frr_lib}/_configmap.tpl"),
    filesha256("${local._frr_lib}/_frrconf.tpl"),
    filesha256("${local._frr_lib}/_volume.tpl"),
  ]))
}

resource "helm_release" "border_router" {
  name              = var.name
  namespace         = var.namespace
  create_namespace  = false
  chart             = "${path.module}/charts/border-router"
  dependency_update = true

  values = [
    yamlencode({
      namespace = var.namespace
      name      = var.name
      images = {
        border = var.image
        frr    = var.frr_image
      }
      ospf             = var.ospf
      templateChecksum = local.template_checksum
    })
  ]
}
