# TFLint — recommended Terraform rules (library holds libvirt + AWS
# modules and Floci-targeted examples; no cloud-provider presets enabled)
config {
  format = "compact"
  plugin_dir = "~/.tflint.d/plugins"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}
