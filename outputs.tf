# Output the swa url
output "static_web_app_url" {
  description = "The default hostname of the static web app"
  value       = azurerm_static_web_app.frontend.default_host_name
}

# Output the swa deployment token 
output "deployment_token" {
  description = "The deployment token for GitHub Actions"
  value       = azurerm_static_web_app.frontend.api_key
  sensitive   = true
}
