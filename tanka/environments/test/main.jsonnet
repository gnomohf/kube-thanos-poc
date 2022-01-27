(import "prometheus.jsonnet") 
+ (import "thanos.jsonnet")

{
   "thanos-query-service"+: {spec+:{
                        type: "NodePort"
   },},
}