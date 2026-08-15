output "jump_vm_public_ip" {
  description = "Public IP address of the Jump VM"
  value       = module.jump_vm.public_ip
}