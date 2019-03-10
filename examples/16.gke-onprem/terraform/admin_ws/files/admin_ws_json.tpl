{
  "DiskProvisioning": "thin",
  "IPAllocationPolicy": "dhcpPolicy",
  "IPProtocol": "IPv4",
  "InjectOvfEnv": true,
  "MarkAsTemplate": false,
  "Name": "Admin-WS",
  "PropertyMapping": [
    {
      "Key": "gwip",
      "Value": "${gateway_ip}"
    }
  ],
  "NetworkMapping": [
    {
      "Name": "VM Network",
      "Network": "VM Network"
    },
    {
      "Name": "internal management",
      "Network": "internal management"
    },
    {
      "Name": "internal vm network",
      "Network": "internal vm network"
    },
    {
      "Name": "external vm network",
      "Network": "external vm network"
    }
  ],
  "PowerOn": true,
  "WaitForIP": false
}