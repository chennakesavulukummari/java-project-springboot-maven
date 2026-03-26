    - To test Kubernetes installation, let’s try to deploy nginx based application and try to access it.
    $ kubectl create deployment nginx-app --image=nginx --replicas=2

    - Check the status of nginx-app deployment
    $ kubectl get deployment nginx-app

    - Expose the deployment as NodePort,
    $ kubectl expose deployment nginx-app --type=NodePort --port=80

    - Run following commands to view service status

    $ kubectl get svc nginx-app
    
    $ kubectl describe svc nginx-app

    - Use following command to access nginx based application,

    $ curl http://<woker-node-ip-addres>:31246

