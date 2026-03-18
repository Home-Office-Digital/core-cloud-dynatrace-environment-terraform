variable "rules" {
  description = "Ordered list of Dynatrace log storage rules. Order matters (first match wins)."

  type = list(object({
    name              = string
    enabled           = optional(bool, true)
    send_to_storage   = optional(bool, true)
    
    matchers = optional(list(object({
      attribute = string
      values    = list(string)
    })), [])
  }))
}
