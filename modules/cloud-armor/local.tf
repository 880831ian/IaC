locals {
  default_rule = {
    action        = var.deny_all ? "deny(403)" : "allow"
    description   = "default rule"
    src_ip_ranges = ["*"]
    priority      = 2147483647
  }
  rule_items = concat(var.rule_items, [local.default_rule])
}