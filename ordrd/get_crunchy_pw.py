#!/usr/bin/env python

import argparse
from kubernetes import client, config
import base64
import urllib3

# Disable SSL warnings
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

def get_k8s_secret(cluster_name, username, namespace):
    # Load the kubeconfig file
    config.load_kube_config()

    # If the namespace is not provided, use the current context's namespace
    if not namespace:
        try:
            # Retrieve the namespace from the current context
            k8s_config = config.list_kube_config_contexts()[1]
            if 'context' in k8s_config and 'namespace' in k8s_config['context']:
                namespace = k8s_config['context']['namespace']
            else:
                namespace = 'default'
        except IndexError:
            # Fallback to 'default' if current context is not set
            namespace = 'default'

    # Create a v1Secret client
    v1 = client.CoreV1Api()

    # Construct the secret name
    secret_name = f"{cluster_name}-pguser-{username}"

    # Try to get the secret
    try:
        secret = v1.read_namespaced_secret(name=secret_name, namespace=namespace)
        encoded_password = secret.data.get("password")
        if encoded_password:
            # Decode the password from base64
            password = base64.b64decode(encoded_password).decode('utf-8')
            print(f"Username: {username:>20}\tPassword: {password}")
        else:
            print(f"Username: {username}, Password key not found in the secret")
    except client.exceptions.ApiException as e:
        print(f"Username: {username}, An error occurred: {e}")

def main():
    parser = argparse.ArgumentParser(description='Get Kubernetes secrets for multiple users in a specific cluster.')
    parser.add_argument('cluster_name', help='Name of the cluster')
    parser.add_argument('usernames', nargs='+', help='Names of the users')
    parser.add_argument('-n', '--namespace', help='Namespace to search for the secret (default: namespace from current context)', default=None)

    args = parser.parse_args()

    for username in args.usernames:
        get_k8s_secret(args.cluster_name, username, args.namespace)

if __name__ == '__main__':
    main()
