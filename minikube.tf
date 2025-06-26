resource "null_resource" "minikube_config" {
  # Use local minikube configuration instead of remote K3s
  provisioner "local-exec" {
    command = "mkdir -p ${path.module}/.kube"
  }

  # Copy minikube kubeconfig to the project directory
  provisioner "local-exec" {
    command = "cp ~/.kube/config ${path.module}/kubeconfig"
  }

  # Ensure the kubeconfig is properly formatted for this project
  provisioner "local-exec" {
    command = "chmod 644 ${path.module}/kubeconfig"
  }
  
  # Set KUBECONFIG environment variable for subsequent commands
  provisioner "local-exec" {
    command = "echo 'export KUBECONFIG=${path.module}/kubeconfig' > ${path.module}/kubeconfig.env"
  }
}

# Wait for minikube cluster to be ready
resource "null_resource" "wait_for_cluster" {
  depends_on = [null_resource.minikube_config]

  provisioner "local-exec" {
    command = "KUBECONFIG=${path.module}/kubeconfig kubectl wait --for=condition=Ready nodes --all --timeout=300s"
  }
}

# Minikube tunnel
resource "null_resource" "minikube_tunnel" {
  depends_on = [null_resource.wait_for_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      # Check if tunnel is already running
      if ! pgrep -f "minikube tunnel" > /dev/null; then
        nohup minikube tunnel > ${path.module}/minikube_tunnel.log 2>&1 &
        echo $! > ${path.module}/minikube_tunnel.pid
        # Wait for tunnel to establish
        sleep 5
      else
        echo "Minikube tunnel is already running"
      fi
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      if [ -f "${path.module}/minikube_tunnel.pid" ]; then
        PID=$(cat "${path.module}/minikube_tunnel.pid")
        if ps -p $PID > /dev/null; then
          kill $PID || true
        fi
        rm -f "${path.module}/minikube_tunnel.pid"
      fi
    EOT
  }
}
